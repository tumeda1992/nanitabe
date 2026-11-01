module Business::Food::Meal::FrameEntry
  class Usecase::AddCommand < ::Business::Food::Meal::Frame::Entry::Usecase::AddCommand
    def call
      # 保存は現行Commandに集約し、旧入口の返却classだけを保つ。
      Business::Food::Meal::FrameEntry::Root.new(super.attributes)
    end
  end
end
