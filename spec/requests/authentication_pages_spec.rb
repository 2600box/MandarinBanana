# -*- coding: utf-8 -*-
require 'spec_helper'

describe "Authentication" do

  before do
    @user = User.create!(name: "foobar", password: "foobar", email: "foobar@example.com", password_confirmation: "foobar")
    @hanzi = Hanzi.create!(character: "大", components: "")
    @pinyindefinition = @hanzi.pinyindefinitions.create!(pinyin: "da4")
    @mnemonic = @user.mnemonics.create!(aide: "Bla", pinyindefinition: @pinyindefinition)
    @fimage = FeaturedImage.new(data: "data:image/png;base64,ABCDEFG", mnemonic_aide: @mnemonic.aide, hanzi_id: @hanzi.id, commentary: "bla")
    @fimage.save
  end

  subject { page }

  describe "signin page" do
    before { visit signin_path }

    it { should have_content('Sign in') }
    it { should have_title('Sign in') }
  end

  describe "signin" do
    before { visit signin_path }

    describe "with invalid information" do
      before { click_button "Sign in" }

      it { should have_title('Sign in') }
      it { should have_selector('div.alert.alert-error', text: 'Invalid') }
      
      describe "after visiting another page" do
        before { click_link "MandarinBanana" }
        it { should_not have_selector('div.alert.alert-error') }
      end
    end

    describe "with valid information" do
      let(:user) { FactoryGirl.create(:user) }
      before { sign_in user }

      it { should have_title(user.name) }
      it { should_not have_link('Users',       href: users_path) }
      it { should have_link('Profile',     href: user_path(user)) }
      it { should have_link('Settings',    href: edit_user_path(user)) }
      it { should have_link('Sign out',    href: signout_path) }
      it { should_not have_link('Sign in', href: signin_path) }

      describe "followed by signout" do
        before { click_link "Sign out" }
        it { should have_link('Sign in') }
      end
    end
  end

  describe "authorization", type: :request do

    describe "for non-signed-in users" do
      let(:user) { FactoryGirl.create(:user) }

      describe "when attempting to visit a protected page" do
        before do
          visit edit_user_path(user)
          fill_in "Email",    with: user.email
          fill_in "Password", with: user.password
          click_button "Sign in"
        end

        describe "after signing in" do

          it "should render the desired protected page" do
            expect(page).to have_title('Edit user')
          end
        end
      end

      describe "in the Users controller" do

        describe "visiting the edit page" do
          before { visit edit_user_path(user) }
          it { should have_title('Sign in') }
        end

        describe "submitting to the update action" do
          before { patch user_path(user) }
          specify { expect(response).to redirect_to(signin_path) }
        end

        describe "visiting the user index" do
          before { visit users_path }
          it { should have_title('Sign in') }
        end
      end
    end

    describe "as wrong user" do
      let(:user) { FactoryGirl.create(:user) }
      let(:wrong_user) { FactoryGirl.create(:user, email: "wrong@example.com") }
      before { sign_in user, no_capybara: true }

      describe "submitting a GET request to the Users#edit action" do
        before { get edit_user_path(wrong_user) }
        specify { expect(response.body).not_to match(full_title('Edit user')) }
        specify { expect(response).to redirect_to(root_path) }
      end

      describe "submitting a PATCH request to the Users#update action" do
        before { patch user_path(wrong_user) }
        specify { expect(response).to redirect_to(root_path) }
      end
    end

    describe "as non-admin user" do
      let(:user) { FactoryGirl.create(:user) }
      let(:non_admin) { FactoryGirl.create(:user) }

      before { sign_in non_admin, no_capybara: true }

      describe "submitting a DELETE request to the Users#destroy action" do
        before { delete user_path(user) }
        specify { expect(response).to redirect_to(root_path) }
      end
    end

    describe "in the Comments controller" do
        
      before do
        @user = User.new(name: "Example User", email: "user@example.com", password: "foobar", password_confirmation: "foobar")
      end
      
      let(:movie) { FactoryGirl.create(:movie) }
      before { @subtitle = movie.subtitles.build(sentence: "大王", filename: "dntg-100-200") }
      
      before { @user.save }
      before { @subtitle.save }
      
      describe "submitting to the create action" do
        before { post comments_path }
        specify { response.should redirect_to(signin_path) }
      end
      
      describe "submitting to the destroy action" do
        let(:comment) { FactoryGirl.create(:comment, user: @user, created_at: 1.day.ago, subtitle: @subtitle, hanzi: nil) }
        before { delete comment_path(comment) }
        specify { response.should redirect_to(signin_path) }
      end
    end
  end
end
