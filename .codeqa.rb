Codeqa.configure do |config|
  config.excludes = ['misc/**/*']

  config.enabled_checker.delete 'CheckRubySyntax'
  config.enabled_checker << 'RubocopLint'
  config.enabled_checker << 'RubocopFormatter'

  %w(AlignHash TrailingComma BlockEndNewline SpaceAfterComma).each do |cop|
    config.rubocop_formatter_cops << cop
  end
#  config.enabled_checker << 'HtmlValidator'
end

