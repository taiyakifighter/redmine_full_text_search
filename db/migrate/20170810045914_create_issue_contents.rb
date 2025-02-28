# For auto load
FullTextSearch::Migration

class CreateIssueContents < ActiveRecord::Migration[4.2]
  def change
    return if reverting? and !table_exists?(:issue_contents)

    options = nil
    contents_limit = nil
    if Redmine::Database.mysql?
      options = "ENGINE=Mroonga DEFAULT CHARSET=utf8mb4"
      contents_limit = 16.megabytes
    end
    create_table :issue_contents, options: options do |t|
      t.integer :project_id
      t.integer :issue_id, unique: true, null: false
      t.text :subject
      t.text :contents, limit: contents_limit
      t.integer :status_id
      t.boolean :is_private

      if Redmine::Database.mysql?
        t.index :contents,
                type: "fulltext",
                comment: "TOKENIZER 'TokenMecab'"
      else
        t.index [:id,
                 :project_id,
                 :issue_id,
                 :subject,
                 :contents,
                 :status_id,
                 :is_private],
                name: "index_issue_contents_pgroonga",
                using: "PGroonga",
                with: [
                  "tokenizer = 'TokenBigramIgnoreBlankSplitSymbolAlphaDigit''",
                  "normalizer = 'NormalizerNFKC(\"unify_kana_case\", true, \"unify_hyphen_and_prolonged_sound_mark\", true, \"unify_middle_dot\", true, \"remove_symbol\", true)'",
                ].join(", ")
      end
    end
  end
end
