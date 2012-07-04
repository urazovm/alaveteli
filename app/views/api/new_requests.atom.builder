atom_feed do |feed|
    feed.title("New requests made to #{@public_body.name}")
    feed.updated(@requests.first.updated_at)

    for request in @requests
        feed.entry(request) do |entry|
            entry.updated(request.updated_at)
            entry.published(request.created_at)
            entry.title(request.title)
            entry.content(content, :type => 'html')
            entry.author do |author|
                author.name(request.user_name)
                if !request.user.nil?
                    author.uri(main_url(user_url(request.user)))
                end
                author.email(request.incoming_email)
            end
        end
    end
end

