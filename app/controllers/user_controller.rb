class UserController < ApplicationController

    def sendMessage

      session[:dialogflow] = "active"

      # Create new Dialogflow client
      project_id = Rails.configuration.dialogflow['project_id']
      language_code = Rails.configuration.dialogflow['language_code']
      session_id = session[:session_id]
      session_client = Google::Cloud::Dialogflow::Sessions.new
      session = session_client.class.session_path project_id, session_id

      # Set start time for db entries
      startTime = Time.now+1.hour

      # Create or update db entries
      if User.find_by(sessionid: session_id).nil?
          User.create(sessionid: session_id, startTime: startTime, endTime: startTime, input: " ")
      end
      currentUser = User.find_by(sessionid: session_id)
      User.find_by(sessionid: session_id).update(endTime: startTime,input: currentUser["input"] +"; "+ params[:message_input_field])

      query_params = Google::Cloud::Dialogflow::V2::QueryParameters.new
      if params[:messageContexts].length > 2

        # Parse string to json
        messageContextsString = params[:messageContexts].gsub("&quot;","\"")
        messageContextsString = "{\"contexts\":" + messageContextsString + "}"
        messageContextsJSON = JSON.parse(messageContextsString,:symbolize_names => true)

        # Create Dialogflow context objects from json
        messageContextsJSON.each do |key, array|
          array.each do |value|
            currentContext = Google::Cloud::Dialogflow::V2::Context.new
            currentContext.name = value[:name]
            currentContext.lifespan_count = value[:lifespan_count]
            fields = []

            # Iterate through parameters of context
            if value[:parameters].nil?
              next
            end
            unless value[:parameters][:fields].nil?
              value[:parameters][:fields].map do |key, value|
                value.map do |value_key, value_item|
                  unless value_item.to_s == "NULL_VALUE" || value_item.to_s == "0.0" || value_item.to_s == "false" || value_item.to_s == ""
                    # Create protobuf value object depending on parameter type
                    case value_key.to_s
                    when "string_value"
                      protobuf_value = Google::Protobuf::Value.new string_value: value_item.to_s
                    when "number_value"
                      protobuf_value = Google::Protobuf::Value.new number_value: value_item.to_f
                    else
                      protobuf_value = nil
                    end
                  end
                  unless protobuf_value.nil?
                    fields.push([key.to_s, protobuf_value])
                  end
                end
              end
              currentContext.parameters = Google::Protobuf::Struct.new(fields: Hash[fields])
              query_params.contexts += [currentContext]
            end
          end
        end
      end

      # For simple text responses
      simpleResponses = []

      # For quick replies
      suggestionResponses = []

      # For basic cards
      basicCardsTexts = []
      basicCardsLinkTexts = []
      basicCardsLinkUrls = []
      basicCardsImgUrls = []

      # For timeOutDuration
      @timeoutDuration = 0

      # Remove line breaks from input message text
      messageText = params[:message_input_field].gsub(/\s+/, ' ')

      # Send user message to Dialogflow
      if not params[:message_input_field].blank?
          params[:message] = params[:message_input_field]
          text_input = Google::Cloud::Dialogflow::V2::TextInput.new
          text_input.text = params[:message]
          text_input.language_code = language_code
          query_input = Google::Cloud::Dialogflow::V2::QueryInput.new
          query_input.text = text_input
          response = session_client.detect_intent(session, query_input, query_params: query_params)
      else
        # Else send quick reply if selected
        if not params[:quickResponse].blank?
          params[:message] = params[:quickResponse]
          query_input = { text: { text: params[:message], language_code: language_code } }
          response = session_client.detect_intent(session, query_input, query_params: query_params)
          end
        end

      # Check if fulfillment message contain message with configured platform type
      fulfillmentMessagesContainPlatform = false
      fulfillmentMessages = response.query_result.fulfillment_messages
      fulfillmentMessages.each {|fulfillmentMessage|
        if fulfillmentMessage.platform.to_s == Rails.configuration.dialogflow['platform']
          fulfillmentMessagesContainPlatform = true
        end
      }

      # Process fulfillment messages
      fulfillmentMessages.each {
        |fulfillmentMessage|

          # Process if fulfillment message is for configurated platform
          if fulfillmentMessage.platform.to_s == Rails.configuration.dialogflow['platform']

            # In case fulfillmentMessage contains simple text responses
            unless fulfillmentMessage.simple_responses.nil?
              fulfillmentMessage.simple_responses.simple_responses.each{ |simpleResponse| simpleResponses << simpleResponse.text_to_speech  }
            end

            # In case fulfillmentMessage contains suggestions (quick replies)
            unless fulfillmentMessage.suggestions.nil?
              fulfillmentMessage.suggestions.suggestions.each{ |suggestion| suggestionResponses << suggestion.title  }
            end

            # In case fulfillmentMessage contains cards
            unless fulfillmentMessage.basic_card.nil?
              basicCardsTexts << fulfillmentMessage.basic_card.formatted_text
              basicCardsLinkTexts << fulfillmentMessage.basic_card.buttons[0].title
              basicCardsLinkUrls << fulfillmentMessage.basic_card.buttons[0].open_uri_action.uri
              basicCardsImgUrls << fulfillmentMessage.basic_card.image.image_uri
            end

        # Process if fulfillment messages does not contain any messages for the specified platform
        elsif fulfillmentMessagesContainPlatform == false

          # In case fulfillmentMessage contains single text message
          unless fulfillmentMessage.text.nil?
            simpleResponses << fulfillmentMessage.text.text.to_s[2...-2]
          end

          # In case fulfillmentMessage contains suggestions (quick replies)
          unless fulfillmentMessage.quick_replies.nil?
            fulfillmentMessage.quick_replies.quick_replies.each{ |quick_reply| suggestionResponses << quick_reply.to_s }
          end

          # In case fulfillmentMessage contains cards
          unless fulfillmentMessage.card.nil?
            basicCardsTexts << fulfillmentMessage.card.title
            basicCardsLinkTexts << fulfillmentMessage.card.buttons[0].text
            basicCardsLinkUrls << fulfillmentMessage.card.buttons[0].postback
            basicCardsImgUrls << fulfillmentMessage.card.image_uri
          end
        end
      }

      # Create json from Dialogflow context objects
      messageContexts = []
      for i in 0..(response.query_result.output_contexts).length-1
        messageContexts << response.query_result.output_contexts[i]
      end
      messageContextsJSON = messageContexts.to_json

      # Params for view
      params[:simpleResponses] = simpleResponses
      params[:suggestionResponses] = suggestionResponses
      params[:basicCardsTexts] = basicCardsTexts
      params[:basicCardsLinkTexts] = basicCardsLinkTexts
      params[:basicCardsLinkUrls] = basicCardsLinkUrls
      params[:basicCardsImgUrls] = basicCardsImgUrls
      params[:messageContexts] = messageContextsJSON

      respond_to do |format|
          format.js
      end
    end
end
