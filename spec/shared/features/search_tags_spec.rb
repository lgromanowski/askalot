require 'spec_helper'

describe 'Search Tags', type: :feature do
  let!(:user) { create :user }

  before :each do
    Shared::Tag.autoimport = true
    Shared::Tag.probe.index.reload

    login_as user

    create :question, tag_list: 'rails,ruby,linux'
  end

  it 'searches tags by name' do
    visit shared.root_path

    click_link 'Tagy'

    fill_in 'q', with: 'r'
    click_button 'search-submit'

    expect(page).to     have_content('rails')
    expect(page).to     have_content('ruby')
    expect(page).not_to have_content('linux')

    fill_in 'q', with: 'ux'
    click_button 'search-submit'

    expect(page).to have_content('linux')
  end
end
