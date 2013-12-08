require 'spec_helper'

describe 'Filter Questions', js: true do
  let(:user) { create :user }

  # TODO (smolnar) check url for serialized params

  before :each do
    login_as user

    5.times  { create :question, tag_list: 'ruby,linux' }
    5.times  { create :question, tag_list: 'elasticsearch' }
    10.times { create :question, tag_list: 'elasticsearch,ruby' }
  end

  it 'filters questions by tag' do
    visit root_path

    click_link 'Otázky'

    fill_in_select2 'question_tags', with: 'elasticsearch'

    list = all('#questions > ol > li')
    expect(list).to have(10).items

    list.each { |item| expect(item).to have_content('elasticsearch') }

    within '.pagination' do
      click_link '2'

      wait_for_remote
    end

    list = all('#questions > ol > li')
    expect(list).to have(5).items

    list.each { |item| expect(item).to have_content('elasticsearch') }
  end

  it 'filters questions by multiple tags' do
    visit root_path

    click_link 'Otázky'

    fill_in_select2 'question_tags', with: 'elasticsearch'
    fill_in_select2 'question_tags', with: 'ruby'

    list = all('#questions > ol > li')
    expect(list).to have(10).times

    list.each do |item|
      expect(item).to have_content('elasticsearch')
      expect(item).to have_content('ruby')
    end

    fill_in_select2 'question_tags', with: 'linux'

    list = all('#questions > ol > li')
    expect(list).to have(0).times
    expect(page).to have_content('Neboli nájdené žiadne otázky.')
  end

  it 'filters questions by question tags' do
    visit root_path

    click_link 'Otázky'

    list = all('#questions > ol > li')

    within list[0] do
      click_link 'elasticsearch'

      wait_for_remote
    end

    list = all('#questions > ol > li')
    expect(list).to have(10).items

    list.each { |item| expect(item).to have_content('elasticsearch') }

    within list[0] do
      click_link 'ruby'

      wait_for_remote
    end

    list = all('#questions > ol > li')
    expect(list).to have(10).items

    list.each do |item|
      expect(item).to have_content('elasticsearch')
      expect(item).to have_content('ruby')
    end
  end

  context 'when changing tabs' do
    let(:questions) { Question.tagged_with('elasticsearch').first(3) }

    before :each do
      questions.each { |q| q.toggle_favoring_by! user }
    end

    it 'persists question filter by tag' do
      visit root_path

      click_link 'Otázky'

      fill_in_select2 'question_tags', with: 'elasticsearch'

      list = all('#questions > ol > li')
      expect(list).to have(10).items

      list.each { |item| expect(item).to have_content('elasticsearch') }

      click_link 'Obľúbené'

      wait_for_remote

      list = all('#questions > ol > li')
      expect(list).to have(3).items

      list.each { |item| expect(item).to have_content('elasticsearch') }
    end

    context 'when navigating in history' do
      it 'correctly filters questions' do
        visit root_path

        click_link 'Otázky'

        fill_in_select2 'question_tags', with: 'elasticsearch'

        click_link 'Obľúbené'

        within '#questions > ol' do
          click_link questions.first.title
        end

        expect(current_path).to eql(question_path(questions.first))

        navigate_back

        list = all('#questions > ol > li')
        expect(list).to have(3).items

        navigate_back

        list = all('#questions > ol > li')
        expect(list).to have(10).items
      end
    end
  end
end
