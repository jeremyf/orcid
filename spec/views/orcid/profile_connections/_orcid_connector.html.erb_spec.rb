require 'spec_helper'

describe 'orcid/profile_connections/_orcid_connector.html.erb', type: :view do
  let(:default_search_text) { 'hello' }
  let(:current_user) { double('User') }
  let(:status_processor) { double('Processor') }
  let(:user) {FactoryGirl.create(User)}
  let(:handler) do
    double(
      'Handler',
      profile_request_pending: true,
      unknown: true,
      authenticated_connection: true,
      pending_connection: true,
      profile_request_in_error: true
    )
  end
  def render_with_params
    allow(view).to receive(:current_user).and_return(user)
    render(
      partial: 'orcid/profile_connections/orcid_connector',
      locals: { default_search_text: default_search_text, status_processor: status_processor, current_user: current_user }
    )
  end

  before do
    status_processor.should_receive(:call).with(current_user).and_yield(handler)
  end
  context 'with :unknown status' do
    it 'renders the options to connect orcid profile' do
      expect(handler).to receive(:unknown).and_yield
      render_with_params

      expect(view).to render_template(partial: 'orcid/profile_connections/_options_to_connect_orcid_profile')
      expect(rendered).to have_tag('.orcid-connector')
    end
  end
  context 'with :authenticated_connection status' do
    let(:profile) { double('Profile', orcid_profile_id: '123-456') }
    it 'renders the options to view the authenticated connection' do
      expect(handler).to receive(:authenticated_connection).and_yield(profile)
      render_with_params

      expect(view).to render_template(partial: 'orcid/profile_connections/_authenticated_connection')
      expect(rendered).to have_tag('.orcid-connector')
    end
  end
  context 'with :pending_connection status' do
    let(:profile) { double('Profile', orcid_profile_id: '123-456') }
    it 'renders the options to view the authenticated connection' do
      expect(handler).to receive(:pending_connection).and_yield(profile)
      render_with_params

      expect(view).to render_template(partial: 'orcid/profile_connections/_pending_connection')
      expect(rendered).to have_tag('.orcid-connector')
    end
  end
end
