require 'hobbit'
require "./heroku/invoice"

class App < Hobbit::Base
  get '/api/invoices' do
    invoice = Heroku::Invoice.new("2016", "09")
    invoice.get
  end
end
