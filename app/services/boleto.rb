require 'boletosimples'
require 'roo'

class Boleto

  def initialize(token, environment)
    BoletoSimples.configure do |c|
      c.environment = (environment.to_sym || ENV['BOLETOSIMPLES_ENV'].to_sym)
      c.access_token = (token || ENV['BOLETOSIMPLES_ACCESS_TOKEN'])
    end
  end

  def create_from_xls(xls_file_path)
    workbook = Roo::Spreadsheet.open(xls_file_path, extension: :xlsx)
    workbook.default_sheet = workbook.sheets[0]
    boletos = []
    ((workbook.first_row + 1)..workbook.last_row).each do |row|
      cep = workbook.row(row)[7].to_s
      phone = workbook.row(row)[5]
      phone = phone.to_s.tr('() -', '') if phone
      cpf = workbook.row(row)[4].to_s
      cpf = cpf.to_s.tr('. -', '').rjust(11, '0') if cpf
      tags = workbook.row(row)[14]
      tags = tags.split(' ') if tags
      boletos << {
          description: workbook.row(row)[0],
          amount: workbook.row(row)[1],
          expire_at: workbook.row(row)[2],
          customer_person_name: workbook.row(row)[3],
          customer_cnpj_cpf: cpf,
          customer_phone_number: phone,
          customer_email: workbook.row(row)[6],
          customer_zipcode: cep,
          customer_address: workbook.row(row)[8],
          customer_address_number: workbook.row(row)[9],
          customer_address_complement: workbook.row(row)[10],
          customer_neighborhood: workbook.row(row)[11],
          customer_city_name: workbook.row(row)[12],
          customer_state: ('SP' ||  workbook.row(row)[14]),
          customer_person_type: 'individual',
          document_type: '99',
          tags: tags
      }
    end

    log = []
    log << "Enviando os registros para API #{Time.now}"
    log << "Temos #{boletos.size} boletos para enviar"
    log << 'Qualquer erro que de na criação do boleto, uma mensagem será mostrada abaixo, caso contrário ele foi criado com sucesso'
    boletos.each do |boleto|
      creation_log = create( boleto )
      log << creation_log if creation_log
      sleep 0.1
    end
    log << "Terminado: #{Time.now}"

    log
  end

  # Criar um boleto passando os dados dos clientes
  # Não vamos salvar clientes pois os dados podem mudar
  def create(boleto_hash)
    bank_billet = BoletoSimples::BankBillet.create(boleto_hash)
    if bank_billet.persisted?
      print '.'
      response = nil #bank_billet.attributes
    else
      response = bank_billet.response_errors
      response[:dados_informados] = boleto_hash
    end
    puts response if response
    response
  rescue => e
    puts e.message
    e.message
  end


end