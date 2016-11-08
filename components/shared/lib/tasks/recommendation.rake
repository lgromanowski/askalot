namespace :recommendation do
  expertise_dataset_f = "/media/dmacjam/Data disc1/git/Askalot-dev/askalot/tmp/expertise-train.dat"
  willingness_dataset_f = "/media/dmacjam/Data disc1/git/Askalot-dev/askalot/tmp/willingness-train.dat"

  desc 'Update features for question recommendation'
  task update_features: :environment do
    #compute_seen_units()
    compute_activity()
    # TODO rec_counr, rec_ctr
  end

  desc 'Append new data from last day to expertise dataset'
  task append_expertise_dataset: :environment do
    last_update = Date.today - 3.days
    till = Date.today - 2.days
    build_expertise_dataset(expertise_dataset_f, last_update, till)
  end

  desc 'Create expertise dataset'
  task create_expertise_dataset: :environment do
    last_update =  Shared::Question.order(:created_at).first.created_at
    till = Date.today - 3.days
    build_expertise_dataset(expertise_dataset_f, last_update, till, append=false)
  end

  desc 'Append new data from last day to willingness dataset'
  task append_willingness_dataset: :environment do
    last_update = Date.yesterday
    build_willigness_dataset(willingness_dataset_f, last_update)
  end

  desc 'Create willigness dataset'
  task create_willingness_dataset: :environment do
    last_update =  Shared::Question.order(:created_at).first.created_at
    build_willigness_dataset(willingness_dataset_f, last_update, append=false)
  end

  desc 'Train classifiers'
  task train: :environment do
    `python scripts/python/Training.py`
  end
end

def build_expertise_dataset(filename, last_update, till, append=true)
  if append
    f = File.open(filename, "a")
  else
    f = File.open(filename, "w")
  end
  manager = Shared::Recommendation::FeaturesManager.new

  # Add all answers.
  answers = Shared::Answer.where('created_at > ?', last_update).where('created_at < ?', till)
  correct_count = 0
  skip_count = 0
  answers.each do |answer|
    skip_flag = true

    #unless manager.is_student(answer.author)
    # 1 - positive votes, BA or positive vote by staff
    if answer.votes_difference > 0 || answer.labels.count > 0 || answer.evaluations.where('value > 0').count > 0
        class_id = 1
        skip_flag = false
        puts 'Class 1'
        # 0 - neutral votes and newer answer added
    elsif answer.votes_difference == 0 && answer.question.answers.where('created_at > ?', answer.created_at).count > 0
        class_id = 0
        skip_flag = false
        puts 'Newer answer added'
        # 0 - negative votes or negative vote from staff
    elsif answer.votes_difference < 0 || answer.evaluations.where('value < 0').count > 0
        class_id = 0
        skip_flag = false
        puts 'Negative votes score or negative votes from teacher'
    end

    if skip_flag
      skip_count += 1
    else
      correct_count += 1
      manager.save_expertise_features(f, answer, answer.question.category, answer.question, answer.author, class_id) unless skip_flag
    end
    manager.update_bow(answer)
  end

  puts 'Correct count: ', correct_count
  puts 'Skip count: ', skip_count
  f.close()
end

def build_willigness_dataset(filename, last_update, append=true)
  if append
    f = File.open(filename, "a")
  else
    f = File.open(filename, "w")
  end
  manager = Shared::Recommendation::FeaturesManager.new

  # Answering is positive example
  answers = Shared::Answer.where('created_at > ?', last_update)
  answers.each do |answer|
    #next unless manager.is_student(answer.author)
    manager.save_willingness_features(f, answer, answer.question.category, answer.author, 1)
  end

  # Commenting is positive example
  comments = Shared::Comment.where('created_at > ?', last_update)
  comments.each do |comment|
    #next unless manager.is_student(comment.author)
    category = comment.commentable.try(:category) || comment.commentable.question.category
    manager.save_willingness_features(f, comment, category, comment.author, 1)
  end

  # View is negative example, if not answered by viewer AND no vote for question
  # AND no vote for answers
  filtered_count = 0
  views = Shared::View.where('created_at > ?', last_update)
  views.each do |view|
    #next unless manager.is_student(view.viewer)
    if view.question.answers.find_by(author: view.viewer).nil? &&
        view.question.votes.by(view.viewer).count == 0 &&
        Shared::Vote.where(votable_type: Shared::Answer, voter_id: view.viewer,
                           votable_id: view.question.answers).count == 0
      manager.save_willingness_features(f, view, view.question.category, view.viewer, 0)
    else
      puts 'Filtered - Class 0'
      filtered_count += 1
    end
  end

  puts 'Filtered class 0 count: ', filtered_count
  f.close()
end

def compute_activity()
  manager = Shared::Recommendation::FeaturesManager.new
  users = Shared::User.where('views_count > 0')
  users.each do |user|
    #between_cqa_activity = manager.between_cqa_activity_time(user)
    #user.profiles.get_feature('BetweenCqaActivity').update(value: )
    avg_cqa_activity = manager.avg_cqa_activity(user)
    user.profiles.get_feature('AvgCqaActivity').update(value: avg_cqa_activity) if avg_cqa_activity > 0
    #user.profiles.get_feature('BetweenCourseActivity').update(value: manager.between_course_activity_time(user))
    avg_course_act = manager.avg_course_activity(user)
    user.profiles.get_feature('AvgCourseActivity').update(value: avg_course_act) if avg_course_act > 0
    recent_answers_count = manager.answers_count_in_last_days_now(user)
    user.profiles.get_feature('RecentAnswersCount').update(value: recent_answers_count) if recent_answers_count > 0
  end
end
