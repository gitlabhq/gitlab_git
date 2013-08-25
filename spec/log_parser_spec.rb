require 'spec_helper'

describe Gitlab::Git::LogParser do

  describe "#self.parse_log" do
    context "log_from_git is a valid log" do
      it "returns the correct log" do
        fake_log = "Karlo Soriano
m@example.com
2013-05-09

 14 files changed, 471 insertions(+)
Dmitriy Zaporozhets
m@example.com
2013-05-08

 1 file changed, 6 insertions(+), 1 deletion(-)
Dmitriy Zaporozhets
m@example.com
2013-05-08

 6 files changed, 19 insertions(+), 3 deletions(-)
Dmitriy Zaporozhets
m@example.com
2013-05-08

 3 files changed, 29 insertions(+), 3 deletions(-)
Dmitriy Zaporozhets
m@example.com
2013-05-08

 3 files changed, 3 deletions(-)";

        lp = Gitlab::Git::LogParser.parse_log(fake_log)
        lp.should eq([
          {author_email: 'm@example.com', author_name: "Karlo Soriano", date: "2013-05-09", additions: 471},
          {author_email: 'm@example.com', author_name: "Dmitriy Zaporozhets", date: "2013-05-08", additions: 6, deletions: 1},
          {author_email: 'm@example.com', author_name: "Dmitriy Zaporozhets", date: "2013-05-08", additions: 19, deletions: 3},
          {author_email: 'm@example.com', author_name: "Dmitriy Zaporozhets", date: "2013-05-08", additions: 29, deletions: 3},
          {author_email: 'm@example.com', author_name: "Dmitriy Zaporozhets", date: "2013-05-08", deletions: 3}])
      end
    end
  end

end
