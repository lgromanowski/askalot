module Notifications::Notifying
  extend ActiveSupport::Concern

  def notify_about(action, resource, initiator: current_user, **options)
    Notifications::Dispatcher.notify(action, initiator, resource, options)
  end
end