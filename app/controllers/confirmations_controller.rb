class ConfirmationsController < Milia::ConfirmationsController

    def update
        if @confirmable.attempt_set_password(user_params)
            # This section is patterned off of devise 3.2.5 confirmations_controller#show

            self.resource = resource_class.confirm_by_token(params[:confirmation_token])
            yield resource if block_given?

            if resource.errors.empty?
                log_action("Invitee Confirmed")
                set_flash_message(:notice, :confirmed) if is_flashing_format?

                # Sign in Automatically
                sign_in_tenanted_and_redirect(resource)
            else
                log_action("Invitee Confirmation Failed")
                respond_with_navigational(resource.errors, :status => :unprocessable_entity) { render :new }
            end
        else
            log_action("Invitee Password set failed")
            prep_do_show() # Prep for the form
            respond_with_navigational(resource.errors, :status => :unprocessable_entity) { render :show } 
        end
    end

    def show
        if @confirmable.new_record? ||
            !::Milia.use_invite_member ||
            @confirmable.skip_confirm_change_password
            
            log_action("Devise pass-thru")
            self.resource = resource_class.confirm_by_token(params[:confirmation_token])
            yield resource if block_given?

            if resource.errors.empty?
                set_flash_message(:notice, :confirmed) if is_flashing_format?
            end

            if @confirmable.skip_confirm_change_password
                sign_in_tenanted_and_redirect(resource)
            end
        else
            log_action("Password set form")
            flash[:notice] = "Please choose a password and confirm it"
            prep_do_show() # Prep for the form
        end
        # else fall thru to show templates which if form to set a password
        # upon SUBMIT, processing will continue from update
    end

    def after_confirmation_path_for(resource_name, resource)
        if user_signed_in?
            root_path
        else
            new_user_session_path
        end
    end

    private
    
    def set_confirmable()
        @confirmable = User.find_or_initialize_with_error_by(:confirmation_token, params[:confirmation_token])
    end
end