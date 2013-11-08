module Concerns::Flash
  def flash_error_messages_for(resource, flash: flash.now, **options)
    messages = resource.errors.full_messages

    flash[:error] = Array.wrap(flash[:error]) + messages unless messages.empty?
  end
end
