require 'spec_helper'

describe Orcid do
  let(:user) { FactoryGirl.create(:user) }
  let(:orcid_profile_id) { '0001-0002-0003-0004' }
  subject { described_class }
  its(:provider) { should respond_to :id }
  its(:provider) { should respond_to :secret }
  its(:mapper) { should respond_to :map }
  its(:use_relative_model_naming?) { should eq true }
  its(:table_name_prefix) { should be_an_instance_of String }

  context '.authentication_model' do
    subject { Orcid.authentication_model }
    it { should respond_to :to_access_token }
    it { should respond_to :create! }
    it { should respond_to :count }
    it { should respond_to :where }
  end

  context '.oauth_client' do
    subject { Orcid.oauth_client }
    its(:client_credentials) { should respond_to :get_token }
  end

  context '.configure' do
    it 'should yield a configuration' do
      expect{|b| Orcid.configure(&b) }.to yield_with_args(Orcid::Configuration)
    end
  end

  context '.profile_for' do
    it 'should return nil if none is found' do
      expect(Orcid.profile_for(user)).to eq(nil)
    end

    it 'should return an Orcid::Profile if the user has an orcid authentication' do
      Orcid.connect_user_and_orcid_profile(user,orcid_profile_id)
      expect(Orcid.profile_for(user).orcid_profile_id).to eq(orcid_profile_id)
    end
  end

  context '.client_credentials_token' do
    let(:tokenizer) { double('Tokenizer') }
    let(:scope) { '/my-scope' }
    let(:token) { double('Token') }

    it 'should request the scoped token from the tokenizer' do
      tokenizer.should_receive(:get_token).with(scope: scope).and_return(token)
      expect(Orcid.client_credentials_token(scope, tokenizer: tokenizer)).to eq(token)
    end
  end

  context '.connect_user_and_orcid_profile' do

    it 'changes the authentication count' do
      expect {
        Orcid.connect_user_and_orcid_profile(user, orcid_profile_id)
      }.to change(Orcid.authentication_model, :count).by(1)
    end
  end

  context '.disconnect_user_and_orcid_profile' do
    it 'changes the authentication count' do
      Orcid.connect_user_and_orcid_profile(user, orcid_profile_id)
      expect { Orcid.disconnect_user_and_orcid_profile(user) }.
        to change(Orcid.authentication_model, :count).by(-1)
    end

    it 'deletes any profile request' do
      Orcid::ProfileRequest.create!(
        user: user, given_names: 'Hello', family_name: 'World',
        primary_email: 'hello@world.com', primary_email_confirmation: 'hello@world.com'
      )
      expect { Orcid.disconnect_user_and_orcid_profile(user) }.
        to change(Orcid::ProfileRequest, :count).by(-1)
    end
  end

  context '.access_token_for' do
    let(:client) { double("Client")}
    let(:token) { double('Token') }
    let(:tokenizer) { double("Tokenizer") }

    it 'delegates to .authentication' do
      tokenizer.should_receive(:to_access_token).with(provider: 'orcid', uid: orcid_profile_id, client: client).and_return(token)
      expect(Orcid.access_token_for(orcid_profile_id, client: client, tokenizer: tokenizer)).to eq(token)
    end
  end

  context '.enqueue' do
    let(:object) { double }

    it 'should #run the object' do
      object.should_receive(:run)
      Orcid.enqueue(object)
    end
  end

  context '#authenticated_orcid' do
    it 'should not be authenticated' do
      Orcid.authenticated_orcid?(orcid_profile_id).should eq false
    end
  end

  context '.url_for_orcid_id' do
    it 'should render a valid uri' do
      profile_id = '123-456'
      uri = URI.parse(Orcid.url_for_orcid_id(profile_id))
      expect(uri.path).to eq('/123-456')
    end
  end

=begin
  context '#authenticated_orcid' do
    it 'should be authenticated' do
      Orcid.should_receive(:authenticated_orcid).with(orcid_profile_id).and_return(true)
      Orcid.authenticated_orcid?(orcid_profile_id).should eq true
    end
  end
=end

end
