require "./heroku/invoice"
require 'hobbit'

class App < Hobbit::Base
  get '/api/invoices/:year/:month' do
    year = request.params[:year]
    month = request.params[:month]
    invoice = Heroku::Invoice.new(year, month)
    invoice.get
  end
end
