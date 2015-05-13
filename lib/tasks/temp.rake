# -*- coding: utf-8 -*-
namespace :temp do


    desc 'Analyse rails log specified by LOG_FILE to produce a list of request volume'
    task :request_volume => :environment do
        example = 'rake log_analysis:request_volume LOG_FILE=log/access_log OUTPUT_FILE=/tmp/log_analysis.csv'
        check_for_env_vars(['LOG_FILE', 'OUTPUT_FILE'],example)
        log_file_path = ENV['LOG_FILE']
        output_file_path = ENV['OUTPUT_FILE']
        is_gz = log_file_path.include?(".gz")
        urls = Hash.new(0)
        f = is_gz ? Zlib::GzipReader.open(log_file_path) : File.open(log_file_path, 'r')
        processed = 0
        f.each_line do |line|
            line.force_encoding('ASCII-8BIT') if RUBY_VERSION.to_f >= 1.9
            if request_match = line.match(/^Started (GET|OPTIONS|POST) "(\/request\/.*?)"/)
                next if line.match(/request\/\d+\/response/)
                urls[request_match[2]] += 1
                processed += 1
            end
        end
        url_counts = urls.to_a
        num_requests_visited_n_times = Hash.new(0)
        CSV.open(output_file_path, "wb") do |csv|
            csv << ['URL', 'Number of visits']
            url_counts.sort_by(&:last).each do |url, count|
                num_requests_visited_n_times[count] +=1
                csv << [url,"#{count}"]
            end
            csv << ['Number of visits', 'Number of URLs']
            num_requests_visited_n_times.to_a.sort.each do |number_of_times, number_of_requests|
                csv << [number_of_times, number_of_requests]
            end
            csv << ['Total number of visits']
            csv << [processed]
        end

    end

    desc 'Look for broken UTF-8 text in IncomingMessage cached_attachment_text_clipped'
    task :find_broken_cached_utf8 => :environment do
        PublicBody.find_each do |public_body|
            begin
                public_body.name.split(' ')
            rescue
                puts "Bad encoding in public_body #{public_body.id} #{public_body.name}"
                public_body.name = public_body.name.force_encoding("cp1252").encode('UTF-8').gsub('’', "'")
                public_body.last_edit_editor = 'system'
                public_body.last_edit_comment = 'Broken utf-8 encoding fixed by temp:find_broken_cached_utf8'
                public_body.save!
                public_body.name.split(' ')
                puts "Fixed #{public_body.id}"
            end
        end

        IncomingMessage.find_each do |incoming_message|
            begin
                incoming_message.get_attachment_text_full.split(' ')
                incoming_message.get_attachment_text_clipped.split(' ')
                incoming_message.get_main_body_text_folded.split(' ')
                incoming_message.get_main_body_text_unfolded.split(' ')
            rescue ArgumentError => e
                puts "Bad encoding in incoming message #{incoming_message.id}"
                incoming_message.clear_in_database_caches!
                incoming_message.get_attachment_text_full.split(' ')
                incoming_message.get_attachment_text_clipped.split(' ')
                incoming_message.get_main_body_text_folded.split(' ')
                incoming_message.get_main_body_text_unfolded.split(' ')
                puts "Fixed #{incoming_message.id}"
            end
        end

    end
end
