# frozen_string_literal: true

RSpec.describe "DB / Slices", :app_integration do
  before do
    @env = ENV.to_h
    allow(Hanami::Env).to receive(:loaded?).and_return(false)
  end

  after do
    ENV.replace(@env)
  end

  specify "using separate relations per slice, while sharing config from the app" do
    with_tmp_directory(@dir = Dir.mktmpdir) do
      write "config/app.rb", <<~RUBY
        require "hanami"

        module TestApp
          class App < Hanami::App
          end
        end
      RUBY

      write "config/providers/db.rb", <<~RUBY
        Hanami.app.configure_provider :db do
          after(:prepare) do
            @rom_config.plugin(:sql, relations: :auto_restrictions)
          end
        end
      RUBY

      write "slices/admin/relations/posts.rb", <<~RUBY
        module Admin
          module Relations
            class Posts < Hanami::DB::Relation
              schema :posts, infer: true
            end
          end
        end
      RUBY

      write "slices/admin/relations/authors.rb", <<~RUBY
        module Admin
          module Relations
            class Authors < Hanami::DB::Relation
              schema :authors, infer: true
            end
          end
        end
      RUBY

      write "slices/main/relations/posts.rb", <<~RUBY
        module Main
          module Relations
            class Posts < Hanami::DB::Relation
              schema :posts, infer: true
            end
          end
        end
      RUBY

      ENV["DATABASE_URL"] = "sqlite://" + Pathname(@dir).realpath.join("database.db").to_s

      require "hanami/prepare"

      Main::Slice.prepare :db

      expect(Main::Slice["db.config"]).to be_an_instance_of ROM::Configuration
      expect(Main::Slice["db.connection"]).to be_an_instance_of ROM::SQL::Gateway

      expect(Admin::Slice.registered?("db.config")).to be false

      Admin::Slice.prepare :db

      expect(Admin::Slice["db.config"]).to be_an_instance_of ROM::Configuration
      expect(Admin::Slice["db.connection"]).to be_an_instance_of ROM::SQL::Gateway

      # Manually run a migration and add a test record
      gateway = Admin::Slice["db.connection"]
      migration = gateway.migration do
        change do
          create_table :posts do
            primary_key :id
            column :title, :text, null: false
          end

          create_table :authors do
            primary_key :id
          end
        end
      end
      migration.apply(gateway, :up)
      gateway.connection.execute("INSERT INTO posts (title) VALUES ('Together breakfast')")

      # Admin slice has appropriate relations registered, and can access data
      expect(Admin::Slice["db.rom"].relations[:posts].to_a).to eq [{id: 1, title: "Together breakfast"}]
      expect(Admin::Slice["relations.posts"]).to be Admin::Slice["db.rom"].relations[:posts]
      expect(Admin::Slice["relations.authors"]).to be Admin::Slice["db.rom"].relations[:authors]

      # Main slice can access data, and only has its own relations (no crossover from admin slice)
      expect(Main::Slice["db.rom"].relations[:posts].to_a).to eq [{id: 1, title: "Together breakfast"}]
      expect(Main::Slice["relations.posts"]).to be Main::Slice["db.rom"].relations[:posts]
      expect(Main::Slice["db.rom"].relations.elements.keys).not_to include :authors
      expect(Main::Slice["relations.posts"]).not_to be Admin::Slice["relations.posts"]

      # Plugins configured in the app's db provider are copied to child slice providers
      expect(Admin::Slice["db.config"].setup.plugins.length).to eq 1
      expect(Admin::Slice["db.config"].setup.plugins).to include an_object_satisfying { |plugin|
        plugin.name == :auto_restrictions && plugin.type == :relation
      }
      expect(Admin::Slice["db.config"].setup.plugins).to eq (Main::Slice["db.config"].setup.plugins)
    end
  end

  specify "disabling sharing of config from the app" do
    with_tmp_directory(@dir = Dir.mktmpdir) do
      write "config/app.rb", <<~RUBY
        require "hanami"

        module TestApp
          class App < Hanami::App
          end
        end
      RUBY

      write "config/providers/db.rb", <<~RUBY
        Hanami.app.configure_provider :db do
          after(:prepare) do
            @rom_config.plugin(:sql, relations: :auto_restrictions)
          end
        end
      RUBY

      write "slices/admin/config/providers/db.rb", <<~RUBY
        Admin::Slice.configure_provider :db do
          config.share_parent_config = false
        end
      RUBY

      ENV["DATABASE_URL"] = "sqlite://" + Pathname(@dir).realpath.join("database.db").to_s

      require "hanami/prepare"

      expect(Admin::Slice["db.config"].setup.plugins.length).to eq 0
    end
  end
end
