// @ts-check
import eslint from '@eslint/js';
import importPlugin from 'eslint-plugin-import';
import perfectionistPlugin from 'eslint-plugin-perfectionist';
import unicornPlugin from 'eslint-plugin-unicorn';
import globals from 'globals';
import tseslint from 'typescript-eslint';

export default tseslint.config(
  {
    ignores: ['eslint.config.mjs', 'prettier.config.mjs', 'dist'],
  },
  {
    plugins: {
      import: importPlugin,
      perfectionist: perfectionistPlugin,
    },
  },
  eslint.configs.recommended,
  ...tseslint.configs.recommendedTypeChecked,
  unicornPlugin.configs.recommended,
  {
    languageOptions: {
      globals: {
        ...globals.node,
        ...globals.jest,
      },
      sourceType: 'commonjs',
      parserOptions: {
        projectService: true,
        tsconfigRootDir: import.meta.dirname,
      },
    },
  },
  {
    rules: {
      '@typescript-eslint/no-non-null-assertion': 'off',

      '@typescript-eslint/no-unused-vars': [
        'error',
        {
          argsIgnorePattern: '^_',
          varsIgnorePattern: '^_',
          caughtErrorsIgnorePattern: '^_',
        },
      ],
      '@typescript-eslint/consistent-type-imports': [
        'warn',
        { prefer: 'type-imports', fixStyle: 'separate-type-imports' },
      ],
      '@typescript-eslint/no-misused-promises': ['error', { checksVoidReturn: { attributes: false } }],
      '@typescript-eslint/no-unnecessary-condition': [
        'error',
        {
          allowConstantLoopConditions: true,
        },
      ],
      '@typescript-eslint/explicit-module-boundary-types': ['error'],
      '@typescript-eslint/array-type': ['warn'],
      '@typescript-eslint/consistent-indexed-object-style': 'off',
      '@typescript-eslint/consistent-type-assertions': 'warn',
      '@typescript-eslint/consistent-type-definitions': ['warn', 'interface'],
      '@typescript-eslint/no-unnecessary-type-assertion': 'warn',
      '@typescript-eslint/explicit-function-return-type': 'error',
      '@typescript-eslint/explicit-member-accessibility': [
        'error',
        {
          accessibility: 'no-public',
        },
      ],
      '@typescript-eslint/naming-convention': [
        'warn',
        {
          selector: 'variable',
          format: ['camelCase', 'UPPER_CASE', 'PascalCase'],
        },
      ],
      '@typescript-eslint/no-empty-function': 'warn',
      '@typescript-eslint/no-empty-interface': 'error',
      '@typescript-eslint/no-explicit-any': 'warn',
      '@typescript-eslint/no-inferrable-types': 'warn',
      '@typescript-eslint/no-shadow': 'off',
      '@typescript-eslint/prefer-nullish-coalescing': 'error',
      '@typescript-eslint/prefer-optional-chain': 'error',
      '@typescript-eslint/no-floating-promises': 'error',
      '@typescript-eslint/await-thenable': 'error',
      '@typescript-eslint/consistent-type-exports': 'error',
      '@typescript-eslint/no-import-type-side-effects': 'error',

      eqeqeq: 'error',
      complexity: ['error', 20],
      curly: 'error',
      'guard-for-in': 'error',
      'max-classes-per-file': ['error', 1],
      'max-len': [
        'warn',
        {
          code: 120,
          comments: 160,
          ignoreStrings: true,
          ignoreTemplateLiterals: true,
        },
      ],
      'max-lines': ['error', 400],
      'no-bitwise': 'error',
      'no-new-wrappers': 'error',
      'no-useless-concat': 'error',
      'no-var': 'error',
      'no-restricted-syntax': 'off',
      'no-shadow': [
        'error',
        {
          allow: ['_', 'idx'],
        },
      ],
      'one-var': ['error', 'never'],
      'prefer-arrow-callback': 'error',
      'prefer-const': 'error',
      'sort-imports': [
        'error',
        {
          ignoreCase: true,
          ignoreDeclarationSort: true,
          allowSeparatedGroups: true,
        },
      ],
      'no-console': 'warn',
      'no-debugger': 'error',
      'no-alert': 'error',
      'object-shorthand': 'error',
      'prefer-template': 'error',
      'prefer-destructuring': ['error', { object: true, array: false }],
      'arrow-body-style': ['error', 'as-needed'],
      'no-useless-return': 'error',
      'no-param-reassign': 'error',
      'no-eval': 'error',
      'no-implied-eval': 'error',

      'unicorn/prevent-abbreviations': 'off',
      'unicorn/filename-case': [
        'error',
        {
          cases: {
            kebabCase: true,
            camelCase: true,
            pascalCase: true,
          },
        },
      ],
      'unicorn/no-null': 'off',
      'unicorn/prefer-module': 'off',
      'unicorn/prefer-node-protocol': 'error',
      'unicorn/prefer-top-level-await': 'off',
      'unicorn/consistent-destructuring': 'error',
      'unicorn/no-array-reduce': 'off',
      'unicorn/numeric-separators-style': 'error',

      'import/consistent-type-specifier-style': ['error', 'prefer-top-level'],

      'perfectionist/sort-array-includes': 'error',
      'perfectionist/sort-enums': 'error',
      'perfectionist/sort-exports': 'error',
      'perfectionist/sort-interfaces': [
        'error',
        {
          newlinesBetween: 0,
          groups: ['index-signature', 'property', 'method'],
        },
      ],
      'perfectionist/sort-intersection-types': 'error',
      'perfectionist/sort-jsx-props': 'error',
      'perfectionist/sort-maps': 'error',
      'perfectionist/sort-modules': 'error',
      'perfectionist/sort-named-exports': 'error',
      'perfectionist/sort-object-types': [
        'error',
        {
          newlinesBetween: 0,
          groups: ['index-signature', 'property', 'method'],
        },
      ],
      'perfectionist/sort-objects': [
        'error',
        {
          newlinesBetween: 0,
          groups: ['property', 'method'],
        },
      ],
      'perfectionist/sort-decorators': 'error',
      'perfectionist/sort-sets': 'error',
      'perfectionist/sort-switch-case': 'error',
      'perfectionist/sort-variable-declarations': 'error',
      'perfectionist/sort-union-types': [
        'error',
        {
          groups: ['nullish'],
        },
      ],
    },
  },
);
