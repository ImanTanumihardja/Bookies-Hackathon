/* global ethers task */
module.exports = task('create-bookie', 'Creates a bookie')
  .addOptionalParam('tournament', 'Address of tournament', "", types.string)
  .setAction(async (taskArgs) => {
    create_bookie = require("../scripts/create_bookie")
    await create_bookie(taskArgs.tournament);
  });