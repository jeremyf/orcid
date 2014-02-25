require 'fast_helper'
require 'app/services/orcid/remote/profile_creation_service'

module Orcid::Remote
  describe ProfileCreationService do
    Given(:payload) { %(<?xml version="1.0" encoding="UTF-8"?>) }
    Given(:config) { {token: token, headers: request_headers, path: 'path/to/somewhere' } }
    Given(:token) { double("Token", post: response) }
    Given(:minted_orcid) { '0000-0001-8025-637X' }
    Given(:request_headers) {
      { 'Content-Type' => 'application/vdn.orcid+xml', 'Accept' => 'application/xml' }
    }
    Given(:callback) { StubCallback.new }
    Given(:callback_config) { callback.configure }

    Given(:response) {
      double("Response", headers: { location: File.join("/", minted_orcid, "orcid-profile") })
    }

    When(:returned_value) { described_class.call(payload, config, &callback_config) }

    context 'with orcid created' do
      Given(:response) {
        double("Response", headers: { location: File.join("/", minted_orcid, "orcid-profile") })
      }
      Then { returned_value.should eq(minted_orcid)}
      And { expect(callback.invoked).to eq [:success, minted_orcid] }
      And { token.should have_received(:post).with(config.fetch(:path), body: payload, headers: request_headers)}
    end

    context 'with orcid created' do
      Given(:response) {
        double("Response", headers: { location: "" })
      }
      Then { returned_value.should eq(false)}
      And { expect(callback.invoked).to eq [:failure] }
      And { token.should have_received(:post).with(config.fetch(:path), body: payload, headers: request_headers)}
    end
  end
end