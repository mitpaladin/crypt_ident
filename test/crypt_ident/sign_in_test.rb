# frozen_string_literal: true

require 'test_helper'

include CryptIdent

describe 'CryptIdent#sign_in' do
  let(:guest_user) { CryptIdent.configure_crypt_ident.guest_user }
  let(:params) do
    { name: 'J Random User', password: 'Suitably Entropic Password!' }
  end
  let(:repo) { UserRepository.new }
  let(:user) do
    saved_user = :unassigned
    sign_up(params, repo: repo, current_user: nil) do |result|
      result.success { |config:, user:| saved_user = user }
      result.failure { |code:, config:| skip }
    end
    saved_user
  end

  describe 'when no Authenticated User is Signed In' do
    describe 'when the correct password is supplied' do
      it 'returns the same User Entity used for Authentication' do
        actual = :unassigned
        sign_in(user, params[:password], current_user: nil) do |result|
          result.success { |user:| actual = user }
          result.failure { next }
        end
        expect(actual).must_equal user
      end
    end # describe 'when the correct password is supplied'

    describe 'when an incorrect password is supplied' do
      it 'returns a :code of :invalid_password' do
        actual = :unassigned
        sign_in(user, 'B@d Passwrod', current_user: guest_user) do |result|
          result.success { next }
          result.failure { |code:| actual = code }
        end
        expect(actual).must_equal :invalid_password
      end
    end # describe 'when an incorrect password is supplied'

    describe 'when Authentication of the Guest User is attempted' do
      it 'returns a :code of :user_is_guest' do
        actual = :unassigned
        sign_in(guest_user, 'anything', current_user: nil) do |result|
          result.success { next }
          result.failure { |code:| actual = code }
        end
        expect(actual).must_equal :user_is_guest
      end
    end # describe 'when Authentication of the Guest User is attempted'
  end # describe 'when no Authenticated User is Signed In'

  describe 'when an Authenticated User is Signed In' do
    let(:other_user) do
      saved_user = :unassigned
      auth_params = { name: 'Another User', password: 'anything' }
      sign_up(auth_params, current_user: nil) do |result|
        result.success { |config:, user:| saved_user = user }
        result.failure { next }
      end
      saved_user
    end

    it 'fails even with a correct password for a different User' do
      actual = :unassigned
      sign_in(user, params[:password], current_user: other_user) do |result|
        result.success { next }
        result.failure { |code:| actual = code }
      end
      expect(actual).must_equal :illegal_current_user
    end
  end # describe 'when an Authenticated User is Signed In'
end
