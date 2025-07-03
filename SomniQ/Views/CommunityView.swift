import SwiftUI

struct CommunityView: View {
    @ObservedObject var dataManager: DataManager
    @Environment(\.dismiss) private var dismiss
    @State private var showingNewPost = false
    @State private var searchText = ""
    @State private var selectedFilter: PostFilter = .all
    
    enum PostFilter: String, CaseIterable {
        case all = "All"
        case support = "Support"
        case tips = "Tips"
        case questions = "Questions"
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search and filter
                searchAndFilterSection
                
                // Posts list
                if dataManager.communityPosts.isEmpty {
                    emptyStateView
                } else {
                    postsList
                }
            }
            .navigationTitle("Community")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingNewPost = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .sheet(isPresented: $showingNewPost) {
            NewPostView(dataManager: dataManager)
        }
    }
    
    private var searchAndFilterSection: some View {
        VStack(spacing: 12) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Search posts...", text: $searchText)
                    .textFieldStyle(.plain)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)
            
            // Filter tabs
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(PostFilter.allCases, id: \.self) { filter in
                        FilterChip(
                            title: filter.rawValue,
                            isSelected: selectedFilter == filter
                        ) {
                            selectedFilter = filter
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding()
        .background(Color(.systemBackground))
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "person.3.fill")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                Text("Welcome to the Community!")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Connect with others who understand what you're going through. Share experiences, ask questions, and find support.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            Button("Create Your First Post") {
                showingNewPost = true
            }
            .buttonStyle(.borderedProminent)
            
            Spacer()
        }
    }
    
    private var postsList: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(filteredPosts) { post in
                    PostCard(post: post, dataManager: dataManager)
                }
            }
            .padding()
        }
    }
    
    private var filteredPosts: [CommunityPost] {
        var posts = dataManager.communityPosts
        
        // Apply search filter
        if !searchText.isEmpty {
            posts = posts.filter { post in
                post.content.localizedCaseInsensitiveContains(searchText) ||
                post.author.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Apply category filter (simplified - in a real app you'd have categories)
        // For now, we'll just return all posts
        
        return posts
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.blue : Color(.systemGray6))
                .cornerRadius(20)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct PostCard: View {
    let post: CommunityPost
    @ObservedObject var dataManager: DataManager
    @State private var showingComments = false
    @State private var newComment = ""
    @State private var showingCommentInput = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 40, height: 40)
                    .overlay(
                        Text(String(post.author.prefix(1)).uppercased())
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(post.author)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    Text(post.date, formatter: relativeDateFormatter)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Menu {
                    Button("Report") {
                        // Handle report
                    }
                    Button("Share") {
                        // Handle share
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundColor(.secondary)
                }
            }
            
            // Content
            Text(post.content)
                .font(.body)
                .multilineTextAlignment(.leading)
            
            // Actions
            HStack(spacing: 20) {
                Button(action: likePost) {
                    HStack(spacing: 4) {
                        Image(systemName: post.likes > 0 ? "heart.fill" : "heart")
                            .foregroundColor(post.likes > 0 ? .red : .secondary)
                        Text("\(post.likes)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .buttonStyle(PlainButtonStyle())
                
                Button(action: { showingComments.toggle() }) {
                    HStack(spacing: 4) {
                        Image(systemName: "bubble.left")
                            .foregroundColor(.secondary)
                        Text("\(post.comments.count)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .buttonStyle(PlainButtonStyle())
                
                Button(action: { showingCommentInput = true }) {
                    HStack(spacing: 4) {
                        Image(systemName: "plus.bubble")
                            .foregroundColor(.secondary)
                        Text("Comment")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .buttonStyle(PlainButtonStyle())
                
                Spacer()
            }
            
            // Comments preview
            if showingComments && !post.comments.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Divider()
                    
                    ForEach(post.comments.prefix(3)) { comment in
                        CommentRow(comment: comment)
                    }
                    
                    if post.comments.count > 3 {
                        Button("View all \(post.comments.count) comments") {
                            // Show all comments
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .alert("Add Comment", isPresented: $showingCommentInput) {
            TextField("Your comment...", text: $newComment)
            Button("Post") {
                addComment()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Share your thoughts on this post")
        }
    }
    
    private func likePost() {
        dataManager.likePost(post)
    }
    
    private func addComment() {
        guard !newComment.isEmpty else { return }
        
        let comment = Comment(
            author: "You",
            content: newComment
        )
        
        dataManager.addComment(to: post, comment: comment)
        newComment = ""
    }
    
    private var relativeDateFormatter: RelativeDateTimeFormatter {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter
    }
}

struct CommentRow: View {
    let comment: Comment
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Circle()
                .fill(Color.green)
                .frame(width: 24, height: 24)
                .overlay(
                    Text(String(comment.author.prefix(1)).uppercased())
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(comment.author)
                    .font(.caption)
                    .fontWeight(.semibold)
                
                Text(comment.content)
                    .font(.caption)
                    .foregroundColor(.primary)
                
                Text(comment.date, formatter: relativeDateFormatter)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
    
    private var relativeDateFormatter: RelativeDateTimeFormatter {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter
    }
}

struct NewPostView: View {
    @ObservedObject var dataManager: DataManager
    @Environment(\.dismiss) private var dismiss
    @State private var postContent = ""
    @State private var selectedCategory: PostCategory = .support
    
    enum PostCategory: String, CaseIterable {
        case support = "Support"
        case tips = "Tips"
        case questions = "Questions"
        case general = "General"
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Category selector
                VStack(alignment: .leading, spacing: 12) {
                    Text("Category")
                        .font(.headline)
                    
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(PostCategory.allCases, id: \.self) { category in
                            Text(category.rawValue).tag(category)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                // Content input
                VStack(alignment: .leading, spacing: 12) {
                    Text("What's on your mind?")
                        .font(.headline)
                    
                    TextField("Share your experience, ask a question, or offer support...", text: $postContent, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(6...12)
                }
                
                Spacer()
                
                // Guidelines
                VStack(alignment: .leading, spacing: 8) {
                    Text("Community Guidelines")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        GuidelineRow(text: "Be supportive and respectful")
                        GuidelineRow(text: "Share personal experiences")
                        GuidelineRow(text: "Ask questions to learn from others")
                        GuidelineRow(text: "Avoid medical advice")
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
            .padding()
            .navigationTitle("New Post")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Post") {
                        createPost()
                    }
                    .disabled(postContent.isEmpty)
                }
            }
        }
    }
    
    private func createPost() {
        let post = CommunityPost(
            author: "You",
            content: postContent
        )
        
        dataManager.addCommunityPost(post)
        dismiss()
    }
}

struct GuidelineRow: View {
    let text: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .font(.caption)
                .foregroundColor(.green)
            
            Text(text)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    CommunityView(dataManager: DataManager())
} 