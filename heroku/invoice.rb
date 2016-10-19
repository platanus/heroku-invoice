require 'json'
require "httparty"
require "nokogiri"

module Heroku
  class Invoice
    attr_accessor :year, :month, :html

    BASE_API_URL = "https://api.heroku.com/invoices/show"
    HEROKU_API_TOKEN = ENV.fetch('HEROKU_API_TOKEN')

    def initialize(year, month)
      @month = month
      @year = year
    end

    def get
      invoice_raw = get_invoice
      respond(invoice_raw)
    end

    private

    def get_invoice
      headers = {
        "Accept": "application/json",
        "Authorization": "Bearer #{HEROKU_API_TOKEN}"
      }

      url = "#{BASE_API_URL}/#{@year}/#{@month}"
      response = HTTParty.get(url, headers: headers)
      response.body
    end

    def respond(invoice_raw)
      invoice_json = JSON.parse(invoice_raw)

      html = Nokogiri::HTML(invoice_json["attrs"]["html"])

      apps = html.css("#more-details > .apps .app").map do |app|

        dynos = app.css("table.dynos tbody tr[id]").map do |dyno|
          {
            name: dyno.css(".dyno_name > text()").text,
            type: dyno.css(".dyno_name > em").text,
            period: to_float(dyno.css(".period").text),
            rate: to_float(dyno.css(".rate").text),
            total: to_float(dyno.css(".total").text)
          }
        end

        addons = app.css("table.addons tbody tr").map do |addon|
          {
            name: addon.css(".name > text()").text,
            period: addon.css(".period span").text,
            rate: to_float(addon.css("td:nth-child(3)").text),
            total: to_float(addon.css("td:nth-child(4)").text)
          }
        end

        {
          name: app.css(".app-title .title").text,
          total: to_float(app.css(".app-total").text),
          dynos: dynos,
          dynos_credit: to_float(app.css("table.dynos tbody .credit td:nth-child(2)").text),
          dynos_total: to_float(app.css("table.dynos tfoot strong").text),
          addons: addons,
          addons_total: to_float(app.css("table.addons tfoot strong").text)
        }
      end

      JSON.dump(
        title: html.css("title").text,
        total: to_float(html.css("#more-details > .total > strong").text),
        finalized: invoice_json["attrs"]["finalized"],
        apps: apps
      )
    end

    def to_float(currency)
      currency.gsub(/[^\d\.]/, '').to_f
    end
  end
end
