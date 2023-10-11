/* global ethers task */
module.exports = task('create-tournament', 'Creates a tournament')
  .addFlag("test")
  .setAction(async (taskArgs) => {
    create_tournament = require("../scripts/create_tournament")
    await create_tournament(taskArgs.test);
  });