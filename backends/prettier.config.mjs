export default {
  plugins: ['@ianvs/prettier-plugin-sort-imports'],
  importOrder: [
    '<TYPES>',
    '<BUILTIN_MODULES>',
    '<THIRD_PARTY_MODULES>',
    '',
    '<TYPES>^@nestjs',
    '^@nestjs/(.*)$',
    '',
    '<TYPES>^[.|..]',
    '^[../]',
    '^[./]',
  ],
  importOrderParserPlugins: ['typescript', 'decorators-legacy'],
  importOrderTypeScriptVersion: '5.9.3',
  printWidth: 120,
  singleQuote: true,
};
