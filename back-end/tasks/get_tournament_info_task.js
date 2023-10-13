/* global ethers task */
module.exports = task('get-tournament-info', 'Get tournament info')
  .addOptionalParam('tournament', 'Address of tournament', "", types.string)
  .setAction(async (taskArgs) => {
    get_tournament_info = require("../scripts/get_tournament_info")
    await get_tournament_info(taskArgs.tournament);
  });