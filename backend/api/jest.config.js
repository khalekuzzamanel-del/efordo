const { createDefaultPreset } = require('ts-jest');

const presetConfig = createDefaultPreset({
  tsconfig: 'tsconfig.json',
});

/** @type {import('@jest/types').Config.InitialOptions} */
const config = {
  ...presetConfig,
  roots: ['<rootDir>/src'],
  testRegex: '.*\\.spec\\.ts$',
  collectCoverageFrom: ['src/**/*.(t|j)s'],
  coverageDirectory: './coverage',
  testEnvironment: 'node',
};

module.exports = config;
