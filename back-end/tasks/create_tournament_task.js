/* global ethers task */
module.exports = task('create-tournament', 'Creates a tournament')
  .addFlag("istest")
  .setAction(async (taskArgs) => {
    create_tournament = require("../scripts/create_tournament")
    await create_tournament(taskArgs.istest);
  });