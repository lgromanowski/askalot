require 'spec_helper'

describe 'Following user', type: :feature do
  let!(:user)       { create :user }
  let!(:other_user) { create :user }

  before :each do
    login_as user

    unless example.metadata[:skip_before]
      user.follow! other_user
    end
  end

  context 'when following from profile page' do
    it 'sets user as follower', skip_before: true do
      visit shared.root_path

      click_link 'Používatelia', match: :first
      click_link other_user.nick, match: :first

      click_link 'Nasledovať'

      expect(page).to have_css('.fa.fa-unlink', count: 1)
      expect(user).to be_following(other_user)
    end

    it 'aborts user as follower' do
      visit shared.root_path

      click_link 'Používatelia', match: :first
      click_link other_user.nick, match: :first

      click_link 'Nenasledovať'

      expect(page).to have_css('.fa.fa-link', count: 1)
      expect(user).not_to be_following(other_user)
    end
  end

  context 'when following from users page', js: true do
    it 'sets user as follower', skip_before: true do
      visit shared.root_path

      click_link 'Používatelia'

      click_link "user-#{other_user.id}-follow"

      expect(page).to have_css('.fa.fa-unlink', count: 1)
      expect(user).to be_following(other_user)
    end

    it 'aborts user as follower' do
      visit shared.root_path

      click_link 'Používatelia'

      click_link "user-#{other_user.id}-unfollow"

      expect(page).to have_css('.fa.fa-link', count: 2)
      expect(user).not_to be_following(other_user)
    end
  end

  context 'when checking followees and followers list', js: true do
    it 'shows followers list' do
      visit shared.root_path

      click_link 'Používatelia'
      click_link other_user.nick, match: :first

      click_link 'nasledovník'

      expect(page).to have_content(user.nick)
    end

    it 'shows followees list' do
      visit shared.root_path

      click_link user.nick

      click_link 'nasledovaný'

      expect(page).to have_content(other_user.nick)
    end
  end
end
