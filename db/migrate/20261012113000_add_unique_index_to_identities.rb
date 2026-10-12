class AddUniqueIndexToIdentities < ActiveRecord::Migration[7.2]
  INDEX_NAME = 'index_identities_on_provider_and_uid'.freeze

  # Stands in for the application's model, so that the migration keeps working as that changes.
  class Identity < ActiveRecord::Base
    self.table_name = 'identities'
  end

  def up
    drop_superseded_identities
    remove_index :identities, name: INDEX_NAME
    add_index :identities, %i[provider uid], unique: true, name: INDEX_NAME
  end

  def down
    remove_index :identities, name: INDEX_NAME
    add_index :identities, %i[provider uid], name: INDEX_NAME
  end

  private

  # A missing provider or uid never collides, since the index counts each null as distinct.
  def drop_superseded_identities
    named = Identity.where.not(provider: nil).where.not(uid: nil)
    named.group(:provider, :uid).count.each do |(provider, uid), rows|
      drop_all_but_oldest(named.where(provider: provider, uid: uid)) if rows > 1
    end
  end

  # Of the rows sharing a provider and uid, only the oldest is reachable: a login looks the
  # identity up and takes the first match. The rest are dropped, leaving the accounts they
  # belong to in place for an administrator to merge.
  def drop_all_but_oldest(duplicated)
    superseded = duplicated.order(:id).drop(1)
    superseded.each do |identity|
      say "Dropping identity #{identity.id} ('#{identity.provider}' / '#{identity.uid}'), which duplicates " \
          "an older one; user #{identity.user_id} may need merging with the account that keeps the identity"
    end
    Identity.where(id: superseded.map(&:id)).delete_all
  end
end
