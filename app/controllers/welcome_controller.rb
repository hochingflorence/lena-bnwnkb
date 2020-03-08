class WelcomeController < ApplicationController

  def index

    session[:dialogflow] = "active"

    # Create new Dialogflow client
    project_id = Rails.configuration.dialogflow['project_id']
    session_id = session[:session_id]
    language_code = "de"
    session_client = Google::Cloud::Dialogflow::Sessions.new
        session = session_client.class.session_path project_id, session_id
    simpleResponses = []
    @initialSuggestions = []

    # Trigger Welcome event in Dialogflow and show response
    query_input = { event: { name: 'WELCOME', language_code: language_code } }
    response = session_client.detect_intent session, query_input

    fulfillmentMessages = response.query_result.fulfillment_messages
    fulfillmentMessages.each {
      |fulfillmentMessage|

      # Process if fulfillment message is for Actions on Google platform
      if fulfillmentMessage.platform.to_s == "ACTIONS_ON_GOOGLE" && fulfillmentMessage.simple_responses.nil? == false
        # Add first simple response as welcome message
        params[:welcomeMessage] = fulfillmentMessage.simple_responses.simple_responses[0].text_to_speech
      end
      
      unless fulfillmentMessage.suggestions.nil?
        fulfillmentMessage.suggestions.suggestions.each { |suggestion| @initialSuggestions.push(suggestion.title) }
      end
    }

  end

end
