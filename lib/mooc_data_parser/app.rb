module MoocDataParser
  require 'json'
  class App

    def run(args)
      init_variables()
      parse_options(args)
      decide_what_to_do(maybe_fetch_json())
      $cache.write_file_to_cache('data.json', @notes.to_json)
    end

    def decide_what_to_do(json)
      if @options.user
        show_info_about(@options.user, 'username', json)
      elsif @options.user_email
        show_info_about(@options.user_email, 'email', json)
      elsif @options.user_tmc_username
        show_info_about(@options.user_tmc_username, 'username', json)
      elsif @options.list
        list_and_filter_participants(json)
      else
        $cache.write_file_to_cache('data.json', @notes.to_json)
        puts @opt
        abort
      end
    end

    def init_variables
      $cache ||= MoocDataParser::DummyCacher.new
      @notes = begin JSON.parse($cache.read_file_from_cache('data.json')) rescue  {} end
    end

    def parse_options(args)
      @options, @opt = MoocDataParser::OptionsParserLogic.new(args).parse
    end

    def maybe_fetch_json()
      if @options.reload or @notes['user_info'].nil? or @notes['week_data'].nil?
        download_data()
      else
        {participants: @notes['user_info'].clone, week_data: @notes['week_data'].clone}
      end
    end

    def download_data
      MoocDataParser::DataDownloader.new(@notes).download!
    end

    def show_info_about(user, user_field = 'username', json)
      participants = json[:participants]
      week_data = json[:week_data]
      my_user = participants.find{|a| a[user_field] == user }

      abort "User not found" if my_user.nil?

      show_user_print_basic_info(my_user)
      show_user_print_completion_percentage(my_user, week_data, participants)  if @options.show_completion_percentige
      show_user_print_missing_points(my_user, week_data) if @options.show_missing_compulsory_points
    end

    def show_user_print_basic_info(my_user)
      formatted_print_user_details ["Username", my_user['username']]
      formatted_print_user_details ["Email", my_user['email']]
      formatted_print_user_details ["Hakee yliopistoon", my_user['hakee_yliopistoon_2014']]
      formatted_print_user_details ["Koko nimi", my_user['koko_nimi']]
    end

    def show_user_print_missing_points(my_user, week_data)
      formatted_print_user_details ["Compulsory points"]
      get_points_info_for_user(my_user, week_data).each do |k,v|
        formatted_print_user_details [k, v.join(", ")]
      end
    end

    def show_user_print_completion_percentage(my_user, week_data, participants)
      formatted_print_user_details ["Points per week"]
      done_exercise_percents(my_user, participants).each do |k|
        begin
          k = k.first
          formatted_print_user_details [k[0], k[1]]
        rescue
          nil
        end
      end
    end

    def formatted_print_user_details(details)
      case details.size
      when 1
        puts "%18s" % details
      when 2
        puts "%18s: %-20s" % details
      end
    end


    def wanted_fields
      %w(username email koko_nimi)
    end

    def list_and_filter_participants(json)
      participants = json[:participants]
      week_data = json[:week_data]
      everyone_in_course = participants.size
      only_applying!(participants)
      hakee_yliopistoon = participants.size

      print_headers()
      process_participants(participants, week_data)
      print_list_stats(everyone_in_course, hakee_yliopistoon)
    end

    def print_headers
      puts "%-20s %-35s %-25s %-120s" % ["Username", "Email", "Real name", "Missing points"]
      puts '-'*200
    end

    def print_list_stats(everyone_in_course, hakee_yliopistoon)
      puts "\n"
      puts "Stats: "
      puts "%25s: %4d" % ["Kaikenkaikkiaan kurssilla", everyone_in_course]
      puts "%25s: %4d" % ["Hakee yliopistoon", hakee_yliopistoon]
    end

    def process_participants(participants, week_data)
      participants.each do |participant|
        nice_string_in_array = wanted_fields.map do |key|
          participant[key]
        end

        to_be_printed = "%-20s %-35s %-25s "

        maybe_add_extra_fields(nice_string_in_array, to_be_printed, participants, participant, week_data)

        puts to_be_printed % nice_string_in_array
      end
    end

    def maybe_add_extra_fields(nice_string_in_array, to_be_printed, participants, participant, week_data)
      if @options.show_completion_percentige
        nice_string_in_array << format_done_exercises_percents(done_exercise_percents(participant, participants))
        to_be_printed << "%-180s "
      end
      if @options.show_missing_compulsory_points
        nice_string_in_array << missing_points_to_list_string(get_points_info_for_user(participant, week_data))
        to_be_printed << "%-120s"
      end
    end

    def format_done_exercises_percents(hash)
      hash.map do |k|
        begin
          k = k.first
          "#{k[0].scan(/\d+/).first}: #{k[1]}"
        rescue
          nil
        end
      end.compact.join(", ")
    end

    def done_exercise_percents(participant, participants_data)
      user_info = participants_data.find{ |p| p['username'] == participant['username'] }
      map_week_keys(user_info)
    end

    def week_keys
      (1..12).map{|i| "viikko#{i}"}
    end

    def map_week_keys(user_info)
      exercise_weeks = user_info['groups']
      week_keys.map do |week|
        details = exercise_weeks[week]
        unless details.nil?
          {week => ("%3.1f%" % [(details['points'].to_f / details['total'].to_f) * 100])}
        end
      end
    end

    def missing_points_to_list_string(missing_by_week)
      str = ""
      missing_by_week.keys.each do |week|
        missing = missing_by_week[week]
        unless missing.nil? or missing.length == 0
          str << week
          str << ": "
          str << missing.join(",")
          str << "  "
        end
      end

      str
    end

    def compulsory_exercises
      # TODO: täydennä data viikolle 12
      {'6' => %w(102.1 102.2 102.3 103.1 103.2 103.3), '7' => %w(116.1 116.2 116.3), '8' => %w(124.1 124.2 124.3 124.4),
       '9' => %w(134.1 134.2 134.3 134.4 134.5), '10' => %w(141.1 141.2 141.3 141.4), '11' => %w(151.1 151.2 151.3 151.4), '12' => %w()}
    end

    def get_points_info_for_user(participant, week_data)
      points_by_week = week_data.keys.each_with_object({}) do |week, points_by_week|
        points_by_week[week] = week_data[week][participant['username']]
      end

      points_by_week.keys.each_with_object({})  do |week, missing_by_week|
        weeks_points = points_by_week[week] || [] #palauttaa arrayn
        weeks_compulsory_points = compulsory_exercises[week] || []
        missing_by_week[week] = weeks_compulsory_points - weeks_points
      end
    end

    def only_applying!(participants)
      participants.select! do |participant|
        participant['hakee_yliopistoon_2014']
      end
    end

  end
end
