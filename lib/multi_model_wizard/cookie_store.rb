# frozen_string_literal: true

module MultiModelWizard
  module CookieStore
    EXPIRATION = 1.hour

    def set_signed_cookie(attributes)
      cookies.signed[attributes[:key]&.to_sym] = {
        value: attributes[:value],
        expires: attributes[:expires] || EXPIRATION.from_now,
        same_site: attributes[:same_site] || 'None',
        secure: attributes[:secure] || true,
        httponly: attributes[:httponly] || true
      }
    end

    def get_signed_cookie(key)
      cookies.signed[key.to_sym]
    end

    def delete_cookie(key)
      cookies.delete(key.to_sym)
    end
  end
end
