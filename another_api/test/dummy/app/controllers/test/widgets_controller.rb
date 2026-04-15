# frozen_string_literal: true

# In-memory "widget" store + an API controller that exercises the engine's
# auth, error handling, and policy plumbing.
module Test
  class WidgetsController < AnotherApi::BaseController
    include Dry::Monads[:result]

    STORE = []

    def index
      api_respond_to_json do
        authorize! with: Test::WidgetsPolicy
        Success(data: STORE.map(&:dup))
      end
    end

    def show
      api_respond_to_json do
        authorize! with: Test::WidgetsPolicy
        widget = STORE.find { |w| w[:id] == params[:id].to_i }
        if widget
          Success(data: widget)
        else
          Failure(:not_found)
        end
      end
    end

    def create
      api_respond_to_json do
        authorize! with: Test::WidgetsPolicy
        case params[:flavour]
        when "string_message"
          Success("a plain string success message")
        when "no_content"
          Success()
        when "operation_failure"
          Failure(AnotherApi::OperationFailure.new(:invalid_field, "name too short", :name))
        when "not_acceptable"
          raise AnotherApi::NotAcceptableError, "no thanks"
        when "unprocessable"
          raise AnotherApi::UnprocessableError, "cannot process"
        when "raw_data"
          Success({id: 1, name: "raw"})
        when "ar_validation_failure"
          # Build an AR record that fails validation, return as Failure[:validation_error, model]
          record = ::Post.new(bearer: nil)  # title required + bearer required → both fail
          record.valid?
          Failure[:validation_error, record]
        when "raised_record_invalid"
          record = ::Post.new(bearer: nil)
          record.save!
        when "raised_validation_error"
          raise ::ActiveModel::ValidationError, ::Post.new(bearer: nil).tap(&:valid?)
        when "raised_parameter_missing"
          raise ::ActionController::ParameterMissing, "name"
        when "failure_forbidden_symbol"
          Failure(:forbidden)
        when "failure_not_permitted_symbol"
          Failure(:not_permitted)
        when "failure_bad_request_symbol"
          Failure(:bad_request)
        when "failure_bogus_symbol"
          Failure(:not_a_real_status_at_all)
        when "raise_forbidden_helper"
          raise_forbidden("nope")
        when "raise_bad_request_helper"
          raise_bad_request("not great")
        when "raise_not_found_helper"
          raise_not_found("missing")
        when "bad_request"
          if params[:name].to_s.empty?
            Failure[:bad_request, "name is required"]
          else
            Failure[:bad_request, "name has bad chars", :name]
          end
        else
          if params[:name].to_s.empty?
            Failure[:bad_request, "name is required"]
          else
            widget = {id: STORE.size + 1, name: params[:name]}
            STORE << widget
            Success(data: widget, status: :created)
          end
        end
      end
    end
  end
end
