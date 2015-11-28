module Shared
class QuestionsController < ApplicationController
  include Shared::Closeables::Close
  include Shared::Deletables::Destroy
  include Shared::Editables::Update
  include Shared::Searchables::Search
  include Shared::Votables::Vote
  include Shared::Watchables::Watch

  include Shared::Events::Dispatch
  include Shared::Markdown::Process
  include Shared::Watchings::Register

  default_tab :recent,  only: :index
  default_tab :results, only: :search

  before_action :authenticate_user!

  def index
    @questions = case params[:tab].to_sym
                 when :unanswered then Question.unanswered.by_votes
                 when :answered   then Question.answered_but_not_best.by_votes
                 when :solved     then Question.solved.by_votes
                 when :favored    then Question.favored.by_votes
                 else Question.recent
                 end

    @questions = filter_questions(@questions)
    @questions = @questions.page(params[:page]).per(20)

    initialize_polling
  end

  def document_index
    @document  = Shared::Document.find(params[:document_id])
    @questions = @document.questions.order(touched_at: :desc)

    @questions = @questions.page(params[:page]).per(20)

    initialize_polling
  end

  def new
    @question = Shared::Question.new

    @question.document = Shared::Document.find(params[:document_id]) if params[:document_id]
    @question.category = Shared::Category.find(params[:category_id]) if params[:category_id]
  end

  def create
    @question = Shared::Question.new(create_params)

    authorize! :ask, @question

    if @question.save
      process_markdown_for @question do |user|
        dispatch_event :mention, @question, for: user
      end

      # TODO (zbell) refactor: do not compose watchers here
      dispatch_event :create, @question, for: @question.parent.watchers + @question.tags.map(&:watchers).flatten, anonymous: @question.anonymous
      register_watching_for @question

      flash[:notice] = t('question.create.success')

      redirect_to question_path(@question)
    else
      render :new
    end
  end

  def show
    @question = Shared::Question.find(params[:id])

    authorize! :view, @question

    @labels  = @question.labels
    @answers = @question.ordered_answers
    @answer  = Shared::Answer.new(question: @question)
    @view    = @question.views.create! viewer: current_user

    @question.increment :views_count

    dispatch_event :create, @view, for: @question.watchers
  end

  def favor
    @question = Shared::Question.find(params[:id])

    authorize! :favor, @question

    @favorite = @question.toggle_favoring_by! current_user

    @question.favorites.reload

    dispatch_event dispatch_event_action_for(@favorite), @favorite, for: @question.watchers
  end

  def suggest
    @questions = Shared::Question.where('id = ? or title like ?', params[:q].to_i, "#{params[:q]}%")

    render json: @questions, root: false
  end

  private

  helper_method :filter_questions

  def initialize_polling
    unless params[:poll]
      session[:poll] = Rails.env_type.development? ? false : true if session[:poll].nil?

      return @poll = params[:poll] = session[:poll]
    end

    @poll = session[:poll] = params[:poll] == 'true' ? true : false
  end

  def filter_questions(relation)
    return relation unless params[:tags].present?

    relation.tagged_with(params[:tags])
  end

  def create_params
    params.require(:question).permit(:title, :text, :category_id, :document_id, :tag_list, :anonymous).merge(author: current_user)
  end

  def update_params
    params.require(:question).permit(:title, :text, :category_id, :tag_list)
  end

  protected

  def destroy_callback(deletable)
    respond_to do |format|
      format.html { redirect_to questions_path, format: :html }
      format.js   { redirect_to document_questions_path(@deletable.parent), format: :js }
    end
  end
end
end
