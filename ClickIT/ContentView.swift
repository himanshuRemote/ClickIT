//
//  ContentView.swift
//  ClickIT
//
//  Created by Himanshu Pharawal on 04/06/25.
//

import SwiftUI
import SFSafeSymbols

// MARK: - Models
struct TaskList: Identifiable, Hashable, Codable {
    let id: UUID
    let name: String
    let icon: String
    let count: Int // This could be a computed property based on tasks.count
    let colorHex: String?
    let iconIsSF: Bool
    var statusSections: [TaskStatusSection] // New property for tasks

    init(id: UUID = UUID(), name: String, icon: String, count: Int, color: Color? = nil, iconIsSF: Bool, statusSections: [TaskStatusSection] = []) {
        self.id = id
        self.name = name
        self.icon = icon
        self.count = count
        self.colorHex = color.map(colorToHex)
        self.iconIsSF = iconIsSF
        self.statusSections = statusSections
    }

    var color: Color? {
        guard let hex = colorHex else { return nil }
        return hexToColor(hex)
    }

    // Computed property for total task count
    var totalTaskCount: Int {
        statusSections.reduce(0) { $0 + $1.tasks.count }
    }
}

struct Space: Identifiable, Hashable, Codable {
    let id: UUID
    let name: String
    let icon: String
    let colorHex: String
    var lists: [TaskList]

    init(id: UUID = UUID(), name: String, icon: String, color: Color, lists: [TaskList]) {
        self.id = id
        self.name = name
        self.icon = icon
        self.colorHex = colorToHex(color)
        self.lists = lists
    }

    var color: Color {
        hexToColor(colorHex) ?? .blue
    }
}

struct TaskAssignee: Identifiable, Hashable, Codable {
    let id: UUID
    let name: String
    let initials: String // e.g., "HP"
    let avatarColorHex: String? // For colored circle background

    init(id: UUID = UUID(), name: String, initials: String, avatarColor: Color? = nil) {
        self.id = id
        self.name = name
        self.initials = initials
        self.avatarColorHex = avatarColor.map(colorToHex)
    }

    var avatarColor: Color? {
        guard let hex = avatarColorHex else { return nil }
        return hexToColor(hex)
    }
}

struct Task: Identifiable, Hashable, Codable {
    let id: UUID
    var name: String
    var assignee: TaskAssignee?
    var dueDate: Date?
    var isCompleted: Bool = false
    var isSubtask: Bool = false
    var parentTaskID: UUID? // For subtasks
    var subtasks: [Task] = [] // Nested subtasks
    var ganttStartDate: Date? // New for Gantt
    var ganttEndDate: Date?   // New for Gantt

    init(id: UUID = UUID(), name: String, assignee: TaskAssignee? = nil, dueDate: Date? = nil, isCompleted: Bool = false, isSubtask: Bool = false, parentTaskID: UUID? = nil, subtasks: [Task] = [], ganttStartDate: Date? = nil, ganttEndDate: Date? = nil) {
        self.id = id
        self.name = name
        self.assignee = assignee
        self.dueDate = dueDate
        self.isCompleted = isCompleted
        self.isSubtask = isSubtask
        self.parentTaskID = parentTaskID
        self.subtasks = subtasks
        self.ganttStartDate = ganttStartDate
        self.ganttEndDate = ganttEndDate
    }
}

struct TaskStatusSection: Identifiable, Hashable, Codable {
    let id: UUID
    var name: String // e.g., "RELEASED", "IN PROGRESS"
    var icon: String // SF Symbol for the status
    var colorHex: String // Color for the status tag
    var tasks: [Task]
    var isCollapsed: Bool = false

    init(id: UUID = UUID(), name: String, icon: String, color: Color, tasks: [Task], isCollapsed: Bool = false) {
        self.id = id
        self.name = name
        self.icon = icon
        self.colorHex = colorToHex(color)
        self.tasks = tasks
        self.isCollapsed = isCollapsed
    }

    var color: Color {
        hexToColor(colorHex) ?? .gray
    }
}

// MARK: - Color <-> Hex helpers (fixed set)
private let colorHexMap: [String: Color] = [
    "#2196F3": .blue,
    "#4CAF50": .green,
    "#F44336": .red,
    "#9C27B0": .purple,
    "#FF9800": .orange,
    "#607D8B": .gray,
    "#000000": .black,
    "#FFFFFF": .white
]

func colorToHex(_ color: Color) -> String {
    for (hex, c) in colorHexMap where c == color { return hex }
    return "#2196F3" // default blue
}

func hexToColor(_ hex: String) -> Color? {
    colorHexMap[hex]
}

// MARK: - Sidebar List Row
struct ListRow: View {
    let list: TaskList
    let isSelected: Bool
    var onIconChange: ((String) -> Void)? = nil
    @State private var isHovering = false
    @State private var isIconHovering = false
    @State private var showIconPicker = false

    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                if list.iconIsSF {
                    Image(systemName: list.icon)
                        .foregroundColor(isSelected ? .purple : .gray)
                        .background(isIconHovering ? Color.gray.opacity(0.2) : Color.clear)
                        .clipShape(Circle())
                        .onHover { hovering in
                            isIconHovering = hovering
                        }
                        .onTapGesture {
                            showIconPicker = true
                        }
                        .popover(isPresented: $showIconPicker) {
                            SFSymbolPicker(selectedIcon: list.icon) { newIcon in
                                onIconChange?(newIcon)
                                showIconPicker = false
                            }
                        }
                } else {
                    Text("Ad")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.gray)
                        .frame(width: 20, height: 20)
                        .background(isIconHovering ? Color.gray.opacity(0.2) : Color(.gray).opacity(0.2))
                        .cornerRadius(4)
                        .onHover { hovering in
                            isIconHovering = hovering
                        }
                        .onTapGesture {
                            showIconPicker = true
                        }
                        .popover(isPresented: $showIconPicker) {
                            SFSymbolPicker(selectedIcon: list.icon) { newIcon in
                                onIconChange?(newIcon)
                                showIconPicker = false
                            }
                        }
                }
            }
            .frame(width: 24, height: 24)
            Text(list.name)
                .foregroundColor(isSelected ? .purple : .primary)
                .fontWeight(isSelected ? .semibold : .regular)
            Spacer()
            if list.count > 0 {
                Text("\(list.count)")
                    .font(.subheadline)
                    .foregroundColor(isSelected ? .purple : .gray)
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 12)
        .background(isSelected ? Color.purple.opacity(0.1) : (isHovering ? Color.gray.opacity(0.08) : Color.clear))
        .cornerRadius(8)
        .contentShape(Rectangle())
        .onHover { hovering in
            isHovering = hovering
            #if os(macOS)
            if hovering {
                NSCursor.pointingHand.push()
            } else {
                NSCursor.pop()
            }
            #endif
        }
    }
}

// Replace IconPicker with SFSymbolPicker
struct SFSymbolPicker: View {
    let allSymbols: [String] = SFSymbol.allSymbols.map { $0.rawValue }
    let selectedIcon: String
    let onSelect: (String) -> Void
    @State private var search: String = ""
    var filteredSymbols: [String] {
        if search.isEmpty { return allSymbols }
        return allSymbols.filter { $0.localizedCaseInsensitiveContains(search) }
    }
    var body: some View {
        VStack(alignment: .leading) {
            TextField("Search symbols", text: $search)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
            ScrollView(.vertical) {
                LazyVGrid(columns: Array(repeating: .init(.flexible()), count: 6), spacing: 12) {
                    ForEach(filteredSymbols, id: \ .self) { icon in
                        Button(action: { onSelect(icon) }) {
                            Image(systemName: icon)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 28, height: 28)
                                .padding(4)
                                .background(icon == selectedIcon ? Color.purple.opacity(0.2) : Color.clear)
                                .cornerRadius(6)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(8)
            }
        }
        .frame(width: 400, height: 320)
    }
}

// MARK: - Sidebar Header
struct SidebarHeader: View {
    let space: Space
    let onAddList: () -> Void
    var body: some View {
        HStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(space.color)
                    .frame(width: 28, height: 28)
                Text(space.icon)
                    .font(.headline)
                    .foregroundColor(.white)
            }
            Text(space.name)
                .font(.headline)
            Spacer()
            Button(action: onAddList) {
                Image(systemName: "plus")
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.top, 12)
        .padding(.bottom, 4)
    }
}

// MARK: - Main ContentView
enum DetailViewType { // New Enum for view switching
    case list, gantt
}

struct ContentView: View {
    @State private var spaces: [Space] = []
    @State private var selectedList: TaskList?
    @State private var selectedSpaceIndex: Int = 0
    @State private var showCreateSpace = false
    @State private var showCreateList = false
    @State private var newSpaceTitle = ""
    @State private var newListTitle = ""
    @State private var newListIcon = "list.bullet"
    @State private var newListCount = 0
    @State private var currentDetailViewType: DetailViewType = .list // New state variable
    // UserDefaults persistence keys
    let spacesKey = "spaces_key"

    // Load spaces from UserDefaults on appear
    private func loadSpaces() {
        if let data = UserDefaults.standard.data(forKey: spacesKey),
           let decoded = try? JSONDecoder().decode([Space].self, from: data) {
            spaces = decoded
        } else {
            // Default data if nothing in UserDefaults
            spaces = [
                Space(
                    name: "Fax",
                    icon: "F",
                    color: .blue,
                    lists: [
                        TaskList(name: "Experiments", icon: "list.bullet.rectangle", count: 3, color: .purple, iconIsSF: true, statusSections: [
                            TaskStatusSection(name: "TO DO", icon: "circle", color: .gray, tasks: [
                                Task(name: "Design new experiment flow", assignee: TaskAssignee(name: "Himanshu P", initials: "HP", avatarColor: .orange), ganttStartDate: Calendar.current.date(byAdding: .day, value: -2, to: Date()), ganttEndDate: Calendar.current.date(byAdding: .day, value: 1, to: Date())),
                                Task(name: "Setup A/B test parameters", ganttStartDate: Calendar.current.date(byAdding: .day, value: 1, to: Date()), ganttEndDate: Calendar.current.date(byAdding: .day, value: 3, to: Date()))
                            ]),
                            TaskStatusSection(name: "IN PROGRESS", icon: "circle.dotted", color: .blue, tasks: [
                                Task(name: "Develop feature X", dueDate: Calendar.current.date(byAdding: .day, value: 3, to: Date()), ganttStartDate: Date(), ganttEndDate: Calendar.current.date(byAdding: .day, value: 5, to: Date()))
                            ], isCollapsed: true),
                             TaskStatusSection(name: "RELEASED", icon: "checkmark.circle.fill", color: .green, tasks: [
                                Task(name: "Launch version 2.2.1", assignee: TaskAssignee(name: "Jane Doe", initials: "JD", avatarColor: .purple), dueDate: Date(), isCompleted: true, subtasks: [
                                    Task(name: "Subtask 2.2.1.1 for v2.2.1 release", isSubtask: true),
                                    Task(name: "Subtask 2.2.1.2 for v2.2.1 release", assignee: TaskAssignee(name: "Himanshu P", initials: "HP", avatarColor: .orange), isSubtask: true)
                                ]),
                                Task(name: "Launch version 2.2.2", isCompleted: true, subtasks: [
                                     Task(name: "Subtask for v2.2.2", isSubtask: true)
                                ])
                            ])
                        ]),
                        TaskList(name: "Releases", icon: "applelogo", count: 1, color: nil, iconIsSF: true, statusSections: [
                            TaskStatusSection(name: "BACKLOG", icon: "circle.dashed", color: .gray, tasks: [
                                Task(name: "Plan Q4 features")
                            ])
                        ]),
                        TaskList(name: "ASA Campaign", icon: "ad", count: 1, color: nil, iconIsSF: false),
                        TaskList(name: "Remote changes", icon: "tv", count: 1, color: nil, iconIsSF: true),
                        TaskList(name: "Questions", icon: "questionmark.circle", count: 4, color: nil, iconIsSF: true),
                        TaskList(name: "Access", icon: "person.2.fill", count: 0, color: nil, iconIsSF: true)
                    ]
                )
            ]
        }
    }

    // Save spaces to UserDefaults
    private func saveSpaces() {
        if let data = try? JSONEncoder().encode(spaces) {
            UserDefaults.standard.set(data, forKey: spacesKey)
        }
    }

    var body: some View {
        NavigationSplitView {
            // Sidebar
            VStack(alignment: .leading, spacing: 0) {
                // New Create Space button at the top
                Button(action: { showCreateSpace = true }) {
                    HStack(spacing: 6) {
                        Image(systemName: "plus")
                        Text("Create Space")
                    }
                    .font(.headline)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 16)
                    .background(Color.gray.opacity(0.12))
                    .cornerRadius(10)
                }
                .accessibilityLabel("Create Space")
                .buttonStyle(.plain)
                .padding(.top, 16)
                .padding(.leading, 8)

                Divider().padding(.vertical, 4)
                if spaces.isEmpty {
                    Text("No spaces available.")
                        .foregroundColor(.secondary)
                        .padding()
                } else {
                    ForEach(spaces.indices, id: \ .self) { idx in
                        let space = spaces[idx]
                        VStack(alignment: .leading, spacing: 0) {
                            // Space header
                            HStack(spacing: 8) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(space.color)
                                        .frame(width: 28, height: 28)
                                    Text(space.icon)
                                        .font(.headline)
                                        .foregroundColor(.white)
                                }
                                Text(space.name)
                                    .font(.headline)
                                Spacer()
                                Button(action: {
                                    selectedSpaceIndex = idx
                                    showCreateList = true
                                }) {
                                    Image(systemName: "plus")
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.horizontal, 12)
                            .padding(.top, 8)
                            .padding(.bottom, 4)
                            // Lists for this space
                            ForEach(space.lists) { list in
                                Button(action: {
                                    selectedSpaceIndex = idx
                                    selectedList = list
                                }) {
                                    ListRow(
                                        list: list,
                                        isSelected: selectedList == list,
                                        onIconChange: { newIcon in
                                            if spaces.indices.contains(idx) {
                                                if let listIdx = spaces[idx].lists.firstIndex(where: { $0.id == list.id }) {
                                                    spaces[idx].lists[listIdx] = TaskList(
                                                        id: list.id,
                                                        name: list.name,
                                                        icon: newIcon,
                                                        count: list.totalTaskCount, // Use computed property
                                                        color: list.color,
                                                        iconIsSF: true,
                                                        statusSections: list.statusSections // Preserve status sections
                                                    )
                                                    if selectedList?.id == list.id {
                                                        selectedList = spaces[idx].lists[listIdx]
                                                    }
                                                }
                                            }
                                        }
                                    )
                                }
                                .buttonStyle(.plain)
                                .contentShape(Rectangle())
                            }
                        }
                        .padding(.bottom, 8)
                    }
                    Spacer()
                }
            }
            .frame(minWidth: 220, idealWidth: 260, maxWidth: 300)
            .background(Color(.white))
        } content: {
            // Content (optional, can be empty or show a placeholder)
            EmptyView()
        } detail: {
            // Detail
            if selectedList != nil, 
               let spaceIdx = spaces.firstIndex(where: { $0.id == spaces[selectedSpaceIndex].id }),
               let taskListIdx = spaces[spaceIdx].lists.firstIndex(where: { $0.id == selectedList!.id }) {
                
                switch currentDetailViewType {
                case .list:
                    TaskListView(taskList: $spaces[spaceIdx].lists[taskListIdx], onDataChange: saveSpaces, currentDetailViewType: $currentDetailViewType)
                case .gantt:
                    GanttChartView(taskList: $spaces[spaceIdx].lists[taskListIdx])
                }

            } else {
        VStack {
                    Text("Select a list")
                        .font(.title2)
                        .foregroundColor(.secondary)
                        .padding()
                    Spacer()
                }
            }
        }
        .sheet(isPresented: $showCreateSpace) {
            VStack(spacing: 20) {
                Text("Create New Space")
                    .font(.headline)
                TextField("Space Title", text: $newSpaceTitle)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                HStack {
                    Button("Cancel") {
                        showCreateSpace = false
                        newSpaceTitle = ""
                    }
                    Spacer()
                    Button("Create") {
                        if !newSpaceTitle.trimmingCharacters(in: .whitespaces).isEmpty {
                            let newSpace = Space(name: newSpaceTitle, icon: String(newSpaceTitle.prefix(1)).uppercased(), color: .green, lists: [])
                            spaces.append(newSpace)
                            selectedSpaceIndex = spaces.count - 1
                            selectedList = nil
                        }
                        showCreateSpace = false
                        newSpaceTitle = ""
                    }
                    .disabled(newSpaceTitle.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                .padding(.horizontal)
            }
            .padding()
            .frame(width: 320)
        }
        .sheet(isPresented: $showCreateList) {
            VStack(spacing: 20) {
                Text("Create New List")
                    .font(.headline)
                TextField("List Title", text: $newListTitle)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
                HStack {
                    Button("Cancel") {
                        showCreateList = false
                        newListTitle = ""
                    }
                    Spacer()
                    Button("Create") {
                        if !newListTitle.trimmingCharacters(in: .whitespaces).isEmpty {
                            let newList = TaskList(name: newListTitle, icon: newListIcon, count: newListCount, color: nil, iconIsSF: true, statusSections: []) // Add empty statusSections
                            if spaces.indices.contains(selectedSpaceIndex) {
                                spaces[selectedSpaceIndex].lists.append(newList)
                            }
                        }
                        showCreateList = false
                        newListTitle = ""
                    }
                    .disabled(newListTitle.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                .padding(.horizontal)
            }
            .padding()
            .frame(width: 320)
        }
        .onAppear {
            loadSpaces()
        }
        .onChange(of: spaces) { oldSpaces, newSpaces in // Updated onChange signature
            // Defensive: If selectedSpaceIndex is out of bounds, reset to 0
            if !newSpaces.indices.contains(selectedSpaceIndex) {
                selectedSpaceIndex = 0
            }
            saveSpaces()
        }
    }
}

// MARK: - Task Views
struct TaskRowView: View {
    @Binding var task: Task
    let level: Int // For indentation of subtasks

    var body: some View {
        HStack(spacing: 8) {
            // Indentation for subtasks
            Spacer().frame(width: CGFloat(level) * 20)

            Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                .foregroundColor(task.isCompleted ? .green : .gray)
                .onTapGesture {
                    task.isCompleted.toggle()
                    // Add save logic if needed immediately
                }

            TextField("Task Name", text: $task.name)
                .textFieldStyle(.plain)
            // TODO: Implement inline editing confirmation/cancellation

            Spacer()

            if let assignee = task.assignee {
                Text(assignee.initials)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .frame(width: 24, height: 24)
                    .background(assignee.avatarColor ?? .gray)
                    .clipShape(Circle())
            } else {
                Image(systemName: "person.circle")
                    .foregroundColor(.gray)
                    .frame(width: 24, height: 24)
            }

            if let dueDate = task.dueDate {
                Text(dueDate, style: .date)
                    .font(.caption)
                    .foregroundColor(.gray)
            } else {
                 Image(systemName: "calendar.badge.plus")
                    .foregroundColor(.gray)
                    .frame(width: 24, height: 24)
            }
            
            Button(action: {
                // Action for the three dots (ellipsis)
                print("More options for task \(task.name)")
            }) {
                Image(systemName: "ellipsis")
            }
            .buttonStyle(.plain)
            .frame(width: 20)


        }
        .padding(.vertical, 4)
        // Recursively display subtasks
        if !task.subtasks.isEmpty {
            ForEach($task.subtasks) { $subtask in
                TaskRowView(task: $subtask, level: level + 1)
            }
        }
    }
}

struct TaskListView: View {
    @Binding var taskList: TaskList
    // Callback to trigger saving data
    var onDataChange: () -> Void
    @Binding var currentDetailViewType: DetailViewType // Added binding


    // Helper to create a date formatter
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }
    
    @State private var showingNewTaskInputForSection: UUID? = nil
    @State private var newTaskName: String = ""
    @State private var levelForNewTaskInput: Int = 0


    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header for the list
            HStack {
                Text("List") // Main title for the task list area
                    .font(.system(size: 18, weight: .semibold))
                Menu {
                    Button(action: { currentDetailViewType = .list }) {
                        Label("List View", systemImage: "list.bullet")
                    }
                    Button(action: { currentDetailViewType = .gantt }) {
                        Label("Gantt Chart", systemImage: "chart.bar.xaxis")
                    }
                } label: {
                    HStack {
                        Image(systemName: "plus")
                        Text("View")
                    }
                }
                .menuStyle(.borderlessButton)
                .fixedSize() // Important for macOS menu button layout
                
                Spacer()
                
                // Top right action buttons (Search, Filter, Customize, Add Task)
                Button(action: { /* Search action */ }) { Image(systemName: "magnifyingglass") }
                Button(action: { /* Filter action */ }) { Image(systemName: "line.3.horizontal.decrease.circle") }
                Button(action: { /* Customize action */ }) { Image(systemName: "slider.horizontal.3") }
                Button(action: { /* Top Add Task action */
                    // Add to the first section if available, or handle appropriately
                    if let firstSectionIdx = taskList.statusSections.firstIndex(where: { $0.id == taskList.statusSections.first?.id }) { // Use firstIndex directly
                        let newTask = Task(name: "New Task from Top")
                        taskList.statusSections[firstSectionIdx].tasks.append(newTask)
                        onDataChange()
                    } else {
                        // Or, create a default section if none exist
                        let newSection = TaskStatusSection(name: "Tasks", icon: "list.bullet", color: .blue, tasks: [Task(name: "New Task from Top")])
                        taskList.statusSections.append(newSection)
                        onDataChange()
                    }
                }) {
                    Text("Add Task")
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(6)
                }
                .buttonStyle(.plain)

            }
            .padding(.horizontal)
            .padding(.top, 12)
            .padding(.bottom, 8)

            List {
                ForEach($taskList.statusSections) { $section in
                    Section {
                        if !section.isCollapsed {
                            ForEach($section.tasks) { $task in
                                TaskRowView(task: $task, level: 0)
                                    .onChange(of: task) { oldTask, newTask in onDataChange() } // Updated onChange signature
                            }
                            // Input field for new task in this section
                            if showingNewTaskInputForSection == section.id {
                                HStack {
                                    Spacer().frame(width: CGFloat(levelForNewTaskInput) * 20) // Indentation
                                    Image(systemName: "circle") // Placeholder icon
                                        .foregroundColor(.gray)
                                    TextField("New Task Name", text: $newTaskName, onCommit: {
                                        if !newTaskName.isEmpty {
                                            let newTask = Task(name: newTaskName)
                                            section.tasks.append(newTask)
                                            newTaskName = ""
                                            showingNewTaskInputForSection = nil
                                            onDataChange()
                                        }
                                    })
                                    .textFieldStyle(.plain)
                                }
                            }
                            
                            Button(action: {
                                 showingNewTaskInputForSection = section.id
                                 newTaskName = "" // Reset for new input
                                 levelForNewTaskInput = 0 // Reset level for section's add task
                            }) {
                                HStack {
                                    Image(systemName: "plus")
                                    Text("Add Task")
                                }
                                .foregroundColor(.gray)
                            }
                            .buttonStyle(.plain)
                            .padding(.leading, 20) // Indent "Add Task" button
                        }
                        
                    } header: {
                        HStack {
                            Button(action: {
                                section.isCollapsed.toggle()
                                onDataChange()
                            }) {
                                Image(systemName: section.isCollapsed ? "chevron.right" : "chevron.down")
                            }
                            .buttonStyle(.plain)

                            Image(systemName: section.icon)
                            Text(section.name)
                                .font(.headline)
                                .foregroundColor(section.color)
                            Text("\(section.tasks.count)")
                                .font(.caption)
                                .foregroundColor(.gray)
                            Spacer()
                            Button(action: {
                                 showingNewTaskInputForSection = section.id
                                 newTaskName = "" 
                                 levelForNewTaskInput = 0 // Reset level for section's add task
                            }) { Image(systemName: "plus") }
                            .buttonStyle(.plain)
                            
                            Button(action: { /* More options for section */ }) { Image(systemName: "ellipsis") }
                            .buttonStyle(.plain)
                        }
                        .padding(.vertical, 5)
                    }
                }
                
                Button(action: {
                    // Action for "+ New status"
                     let newStatus = TaskStatusSection(name: "New Status", icon: "circle", color: .gray, tasks: [])
                     taskList.statusSections.append(newStatus)
                     onDataChange()
                }) {
                    HStack {
                        Image(systemName: "plus")
                        Text("New status")
                    }
                    .foregroundColor(.gray)
                }
                .buttonStyle(.plain)
                .padding(.top, 8)
            }
            .listStyle(.plain) // Use plain list style for closer appearance to image
        }
        .background(Color(.controlBackgroundColor)) // Typical macOS background
    }
}

// MARK: - Gantt Chart Views

struct TimelineView: View {
    let dayWidth: CGFloat = 50
    let hourHeight: CGFloat = 24 // If we want to show hours later
    let days: [Date]

    private var dayFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "d" // Day of the month
        return formatter
    }
    
    private var monthHeaderFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM YYYY"
        return formatter
    }
    
    private var weekDayFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "EE" // Short day name e.g. Mon
        return formatter
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Month Header (spanning multiple days)
            // This needs more sophisticated logic to group days by month
            Text(days.first.map { monthHeaderFormatter.string(from: $0) } ?? "Month")
                .font(.headline)
                .padding(.leading, 5)
                .padding(.bottom, 2)
            
            // Day Headers
            HStack(spacing: 0) {
                ForEach(days, id: \.self) { day in
                    VStack(spacing: 2) {
                        Text(weekDayFormatter.string(from: day))
                            .font(.caption2)
                        Text(dayFormatter.string(from: day))
                            .font(.caption)
                    }
                    .frame(width: dayWidth, height: 30)
                    .background(Calendar.current.isDateInToday(day) ? Color.blue.opacity(0.3) : Color.gray.opacity(0.1))
                    .border(Color.gray.opacity(0.3), width: 0.5)
                }
            }
        }
    }
}

struct GanttBarView: View {
    let task: Task
    let dayWidth: CGFloat
    let timelineStartDate: Date
    
    var body: some View {
        if let startDate = task.ganttStartDate, let endDate = task.ganttEndDate {
            let duration = Calendar.current.dateComponents([.day], from: startDate, to: endDate).day ?? 0
            let offsetDays = Calendar.current.dateComponents([.day], from: timelineStartDate, to: startDate).day ?? 0
            
            if duration >= 0 && offsetDays >= 0 { // Basic validation
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.blue.opacity(0.7))
                    .frame(width: CGFloat(duration + 1) * dayWidth - 2, height: 20) // -2 for slight padding
                    .overlay(Text(task.name).font(.caption).foregroundColor(.white).padding(.horizontal, 4), alignment: .leading)
                    .offset(x: CGFloat(offsetDays) * dayWidth + 1)
                    .padding(.vertical, 2)
            } else {
                EmptyView()
            }
        } else {
            EmptyView()
        }
    }
}

struct GanttChartView: View {
    @Binding var taskList: TaskList
    let dayWidth: CGFloat = 50
    
    // Calculate a range of days to display (e.g., 30 days from the earliest task start)
    var dateRange: [Date] {
        let allDates = taskList.statusSections.flatMap { $0.tasks }
            .flatMap { [$0.ganttStartDate, $0.ganttEndDate] }
            .compactMap { $0 }
        
        guard !allDates.isEmpty, let minDate = allDates.min() else {
            // Default to today and next 30 days if no dates
            return (0..<30).map { Calendar.current.date(byAdding: .day, value: $0, to: Date())! }
        }
        
        let startDate = Calendar.current.startOfDay(for: minDate)
        // Display a fixed range for now, e.g., 60 days
        return (0..<60).map { Calendar.current.date(byAdding: .day, value: $0, to: startDate)! }
    }
    
    var timelineStartDate: Date {
        dateRange.first ?? Calendar.current.startOfDay(for: Date())
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Top Header (similar to TaskListView's header)
            HStack {
                Text("Gantt") // Main title for the task list area
                    .font(.system(size: 18, weight: .semibold))
                // Placeholder for "+ View" menu, to be added in ContentView integration step
                Spacer()
                // Add other action buttons if needed, similar to TaskListView
        }
        .padding()
            
            ScrollView([.horizontal, .vertical]) {
                VStack(alignment: .leading, spacing: 0) {
                    TimelineView(days: dateRange)
                    
                    // Task Rows
                    ForEach(taskList.statusSections) { section in
                        // Section Header (optional, or integrate tasks directly)
                        // Text(section.name).font(.caption).padding(.leading)
                        ForEach(section.tasks.filter { $0.ganttStartDate != nil && $0.ganttEndDate != nil }) { task in
                            // This ZStack will layer the task name on the left and the bar on the timeline part
                            HStack(spacing: 0) {
                                // Task Name column (fixed width)
                                Text(task.name)
                                    .font(.callout)
                                    .frame(width: 150, alignment: .leading)
                                    .padding(.leading)
                                    .border(Color.gray.opacity(0.2), width: 0.5) // Visual separator

                                // Gantt Bar area
                                ZStack(alignment: .leading) {
                                    // Background grid for days (matches TimelineView)
                                    HStack(spacing: 0) {
                                        ForEach(dateRange, id: \.self) { day in
                                            Rectangle()
                                                .fill(Color.clear) // Transparent, just for structure
                                                .frame(width: dayWidth)
                                                .border(Color.gray.opacity(0.2), width: 0.5)
                                        }
                                    }
                                    GanttBarView(task: task, dayWidth: dayWidth, timelineStartDate: timelineStartDate)
                                }
                                .frame(height: 30) // Height of each task row
                            }
                        }
                    }
                }
            }
        }
        .background(Color(.controlBackgroundColor))
    }
}

#Preview {
    ContentView()
}
