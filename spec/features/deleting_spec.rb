require 'spec_helper'

describe 'Deleting', js: true do
  let!(:question)     { create :question, :with_tags, title: 'Deleting question' }
  let(:user)          { create :user }
  let(:administrator) { create :administrator }

  context 'when question has no comments and answers' do
    before :each do
      login_as question.author
    end

    it 'can delete question', js: true do
      visit root_path

      click_link 'Otázky'

      click_link question.title

      click_link "question-#{question.id}-delete-modal"

      within "#question-#{question.id}-deleting" do
        click_link 'Zmazať'
      end

      expect(page).to have_content('Otázka bola úspešne zmazaná.')

      expect(page.current_path).to eql(questions_path)
    end
  end

  context 'when question has answer without comments' do
    let!(:answer) { create :answer, question: question }

    before :each do
      login_as answer.author
    end
    it 'can delete answer', js: true do
      visit root_path

      click_link 'Otázky'

      click_link question.title

      click_link "answer-#{answer.id}-delete-modal"

      within "#answer-#{answer.id}-deleting" do
        click_link 'Zmazať'
      end

      expect(page).to have_content('Odpoveď bola úspešne zmazaná.')

      expect(page.current_path).to eql(question_path question)
    end
  end

  context 'when question has answer with comment' do
    let!(:answer) { create :answer, question: question }
    let!(:comment_answer) { create :comment, commentable: answer, author: user }
    let!(:comment_question) { create :comment, commentable: question, author: user }

    before :each do
      login_as user
    end

    it 'can delete answer comment', js: true do
      visit root_path

      click_link 'Otázky'

      click_link question.title

      click_link "comment-#{comment_answer.id}-delete-modal"

      within "#comment-#{comment_answer.id}-deleting" do
        click_link 'Zmazať'
      end

      expect(page).to have_content('Komentár bol úspešne zmazaný.')

      expect(page.current_path).to eql(question_path question)
    end

    it 'can delete question comment', js: true do
      visit root_path

      click_link 'Otázky'

      click_link question.title

      click_link "comment-#{comment_question.id}-delete-modal"

      within "#comment-#{comment_question.id}-deleting" do
        click_link 'Zmazať'
      end

      expect(page).to have_content('Komentár bol úspešne zmazaný.')

      expect(page.current_path).to eql(question_path question)
    end
  end

  context 'when question has answer with comments and and user is question author' do
    let!(:answer) { create :answer, question: question }
    let!(:comment) { create :comment, commentable: answer }

    before :each do
      login_as question.author
    end

    it 'does not delete the question', js: true do
      visit root_path

      click_link 'Otázky'

      click_link question.title

      expect(page).not_to have_css("#question-#{question.id}-delete-modal")
    end

    it 'does not delete the answer', js: true do
      visit root_path

      click_link 'Otázky'

      click_link question.title

      expect(page).not_to have_css("#answer-#{answer.id}-delete-modal")
    end

    it 'does not delete the comment', js: true do
      visit root_path

      click_link 'Otázky'

      click_link question.title

      expect(page).not_to have_css("#comment-#{comment.id}-delete-modal")
    end
  end

  context 'when question has answer with comments and user is answer author' do
    let!(:answer) { create :answer, question: question }
    let!(:comment) { create :comment, commentable: answer }

    before :each do
      login_as answer.author
    end
    it 'does not delete the question', js: true do
      visit root_path

      click_link 'Otázky'

      click_link question.title

      expect(page).not_to have_css("#question-#{question.id}-delete-modal")
    end

    it 'does not delete the answer', js: true do
      visit root_path

      click_link 'Otázky'

      click_link question.title

      expect(page).not_to have_css("#answer-#{answer.id}-delete-modal")
    end

    it 'does not delete the comment', js: true do
      visit root_path

      click_link 'Otázky'

      click_link question.title

      expect(page).not_to have_css("#comment-#{comment.id}-delete-modal")
    end
  end

  context 'when question has answer with comments and user does not have permissions' do
    let!(:answer) { create :answer, question: question }
    let!(:comment) { create :comment, commentable: answer }

    before :each do
      login_as user
    end
    it 'does not delete the question', js: true do
      visit root_path

      click_link 'Otázky'

      click_link question.title

      expect(page).not_to have_css("#question-#{question.id}-delete-modal")
    end

    it 'does not delete the answer', js: true do
      visit root_path

      click_link 'Otázky'

      click_link question.title

      expect(page).not_to have_css("#answer-#{answer.id}-delete-modal")
    end

    it 'does not delete the comment', js: true do
      visit root_path

      click_link 'Otázky'

      click_link question.title

      expect(page).not_to have_css("#comment-#{comment.id}-delete-modal")
    end
  end

  context 'when question has answer with comments and user is administrator' do
    let!(:answer) { create :answer, question: question }
    let!(:comment) { create :comment, commentable: answer }

    before :each do
      login_as administrator
    end
    it 'can delete question', js: true do
      visit root_path

      click_link 'Otázky'

      click_link question.title

      expect(page).to have_css("#question-#{question.id}-delete-modal")
    end

    it 'can delete answer', js: true do
      visit root_path

      click_link 'Otázky'

      click_link question.title

      expect(page).to have_css("#answer-#{answer.id}-delete-modal")
    end

    it 'can delete comment', js: true do
      visit root_path

      click_link 'Otázky'

      click_link question.title

      expect(page).to have_css("#comment-#{comment.id}-delete-modal")
    end
  end
end