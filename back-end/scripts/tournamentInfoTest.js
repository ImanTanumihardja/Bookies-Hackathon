/* global ethers */
module.exports = {
   TournamentInfo: {
    name: "Test Tournament",
    updateInterval: 3600,
    teamCount: 8,
    gameDays: [Math.trunc(Date.now() / 1000) + 60 * 10],
    gameCount: 7,
    startDate: Math.trunc(Date.now() / 1000) + 60 * 10,
    endDate: Math.trunc(Date.now() / 1000) + 60 * 15,
    oracle: "0xB9756312523826A566e222a34793E414A81c88E1",
    jobId: "0x3662303964333762323834663436353562623531306634393465646331313166",
    sportsId: 11,
    apiRequestFee: ethers.BigNumber.from("100000000000000000"),
    gasLimit: 500000
  }
}