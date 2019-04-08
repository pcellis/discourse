module Jobs
  class ProcessImap < Jobs::Base
    sidekiq_options queue: 'low'

    def execute(args)
      @args = args

      type = args[:type]
      import_mode = args[:import_mode]
      group = Group.find_by(id: @args[:group_id])
      mailbox = Mailbox.find_by(id: args[:mailbox_id])
      uid_validity = args[:uid_validity]
      email = args[:email]

      if type == :old
        incoming_email = IncomingEmail.find_by(
          imap_uid_validity: uid_validity,
          imap_uid: email["UID"]
        )
      elsif type == :new
        begin
          receiver = Email::Receiver.new(email["RFC822"],
            force_sync: true,
            import_mode: import_mode,
            destinations: [{ type: :group, obj: group }],
            uid_validity: uid_validity,
            uid: email["UID"]
          )
          receiver.process!
          incoming_email = receiver.incoming_email
        rescue Email::Receiver::ProcessingError => e
        end
      end

      imap_sync = Imap::Sync.for_group(group)
      imap_sync.update_topic(email, incoming_email, mailbox: mailbox)

      nil
    end
  end
end
