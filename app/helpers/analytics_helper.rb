module AnalyticsHelper
  def analytics_attributes(category, action, label, options = {})
    options.deep_merge data: { :'track-category' => category, :'track-action' => action, :'track-label' => label}
  end
end