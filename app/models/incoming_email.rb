# frozen_string_literal: true

class IncomingEmail < ActiveRecord::Base
  belongs_to :user
  belongs_to :topic
  belongs_to :post
  belongs_to :group, foreign_key: :imap_group_id, class_name: 'Group'

  scope :errored,  -> { where("NOT is_bounce AND error IS NOT NULL") }

  scope :addressed_to, -> (email) do
    where(<<~SQL, email: "%#{email}%")
      incoming_emails.from_address = :email OR
      incoming_emails.to_addresses ILIKE :email OR
      incoming_emails.cc_addresses ILIKE :email
    SQL
  end

  scope :addressed_to_user, ->(user) do
    where(<<~SQL, user_id: user.id)
      EXISTS(
          SELECT 1
          FROM user_emails
          WHERE user_emails.user_id = :user_id AND
                (incoming_emails.from_address = user_emails.email OR
                 incoming_emails.to_addresses ILIKE '%' || user_emails.email || '%' OR
                 incoming_emails.cc_addresses ILIKE '%' || user_emails.email || '%')
      )
    SQL
  end

  def to_addresses=(to)
    if to&.is_a?(Array)
      to = to.map(&:downcase).join(";")
    end
    super(to)
  end

  def cc_addresses=(cc)
    if cc&.is_a?(Array)
      cc = cc.map(&:downcase).join(";")
    end
    super(cc)
  end

  def from_address=(from)
    if from&.is_a?(Array)
      from = from.first
    end
    super(from)
  end
end

# == Schema Information
#
# Table name: incoming_emails
#
#  id                :integer          not null, primary key
#  user_id           :integer
#  topic_id          :integer
#  post_id           :integer
#  raw               :text
#  error             :text
#  message_id        :text
#  from_address      :text
#  to_addresses      :text
#  cc_addresses      :text
#  subject           :text
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  rejection_message :text
#  is_auto_generated :boolean          default(FALSE)
#  is_bounce         :boolean          default(FALSE), not null
#  imap_uid_validity :integer
#  imap_uid          :integer
#  imap_sync         :boolean
#  imap_group_id     :bigint
#
# Indexes
#
#  index_incoming_emails_on_created_at     (created_at)
#  index_incoming_emails_on_error          (error)
#  index_incoming_emails_on_imap_group_id  (imap_group_id)
#  index_incoming_emails_on_imap_sync      (imap_sync)
#  index_incoming_emails_on_message_id     (message_id)
#  index_incoming_emails_on_post_id        (post_id)
#  index_incoming_emails_on_user_id        (user_id) WHERE (user_id IS NOT NULL)
#
