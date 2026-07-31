
# Mailer Conventions

- Always provide both HTML and text templates
- Use `deliver_later` (async via Solid Queue), never `deliver_now` in controllers
- Create mailer previews in `spec/mailers/previews/` or `test/mailers/previews/`
- Test with `have_enqueued_mail(MailerClass, :method_name)`
- Keep mailer logic minimal -- formatting belongs in presenters
