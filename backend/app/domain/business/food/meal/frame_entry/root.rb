module Business::Food::Meal::FrameEntry
  class Root < ::Business::Food::Meal::Frame::Entry::Root
    # 旧Rootの公開interfaceを維持する。未割当化は現行namespaceの操作。
    undef_method :unassign_meal
  end
end
