# frozen_string_literal: true

class AddDeviseToUsuarios < ActiveRecord::Migration[7.0]
  def change
    # Database authenticatable
    add_column :usuarios, :encrypted_password, :string, null: false, default: ""

    # Recoverable
    add_column :usuarios, :reset_password_token, :string
    add_column :usuarios, :reset_password_sent_at, :datetime

    # Rememberable
    add_column :usuarios, :remember_created_at, :datetime

    # Trackable (opcional, descomenta si lo usás)
    # add_column :usuarios, :sign_in_count, :integer, default: 0, null: false
    # add_column :usuarios, :current_sign_in_at, :datetime
    # add_column :usuarios, :last_sign_in_at, :datetime
    # add_column :usuarios, :current_sign_in_ip, :string
    # add_column :usuarios, :last_sign_in_ip, :string

    # Confirmable (opcional)
    # add_column :usuarios, :confirmation_token, :string
    # add_column :usuarios, :confirmed_at, :datetime
    # add_column :usuarios, :confirmation_sent_at, :datetime
    # add_column :usuarios, :unconfirmed_email, :string

    # Lockable (opcional)
    # add_column :usuarios, :failed_attempts, :integer, default: 0, null: false
    # add_column :usuarios, :unlock_token, :string
    # add_column :usuarios, :locked_at, :datetime

    # Indexes
    add_index :usuarios, :reset_password_token, unique: true
    # add_index :usuarios, :confirmation_token, unique: true
    # add_index :usuarios, :unlock_token, unique: true
  end
end
