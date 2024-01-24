//
//  File.swift
//  
//
//  Created by Colin Yang on 2024/1/23.
//

import Foundation

public struct ImageVisionQuery: Equatable, Codable, Streamable {
    /// ID of the model to use. Currently, only gpt-3.5-turbo and gpt-3.5-turbo-0301 are supported.
    public let model: Model
    /// An object specifying the format that the model must output.
    public let responseFormat: ResponseFormat?
    
    /// The messages to generate chat completions for
    public let messages: [ImageVisionChat]
    
    /// A list of functions the model may generate JSON inputs for.
    public let functions: [ChatFunctionDeclaration]?
    
    /// Controls how the model responds to function calls. "none" means the model does not call a function, and responds to the end-user. "auto" means the model can pick between and end-user or calling a function. Specifying a particular function via `{"name": "my_function"}` forces the model to call that function. "none" is the default when no functions are present. "auto" is the default if functions are present.
    public let functionCall: FunctionCall?
    /// What sampling temperature to use, between 0 and 2. Higher values like 0.8 will make the output more random, while lower values like 0.2 will make it more focused and  We generally recommend altering this or top_p but not both.
    public let temperature: Double?
    /// An alternative to sampling with temperature, called nucleus sampling, where the model considers the results of the tokens with top_p probability mass. So 0.1 means only the tokens comprising the top 10% probability mass are considered.
    public let topP: Double?
    /// How many chat completion choices to generate for each input message.
    public let n: Int?
    /// Up to 4 sequences where the API will stop generating further tokens. The returned text will not contain the stop sequence.
    public let stop: [String]?
    /// The maximum number of tokens to generate in the completion.
    public let maxTokens: Int?
    /// Number between -2.0 and 2.0. Positive values penalize new tokens based on whether they appear in the text so far, increasing the model's likelihood to talk about new topics.
    public let presencePenalty: Double?
    /// Number between -2.0 and 2.0. Positive values penalize new tokens based on their existing frequency in the text so far, decreasing the model's likelihood to repeat the same line verbatim.
    public let frequencyPenalty: Double?
    /// Modify the likelihood of specified tokens appearing in the completion.
    public let logitBias: [String:Int]?
    /// A unique identifier representing your end-user, which can help OpenAI to monitor and detect abuse.
    public let user: String?
    
    var stream: Bool = false

    public enum FunctionCall: Codable, Equatable {
        case none
        case auto
        case function(String)
        
        enum CodingKeys: String, CodingKey {
            case none = "none"
            case auto = "auto"
            case function = "name"
        }
        
        public func encode(to encoder: Encoder) throws {
            switch self {
            case .none:
                var container = encoder.singleValueContainer()
                try container.encode(CodingKeys.none.rawValue)
            case .auto:
                var container = encoder.singleValueContainer()
                try container.encode(CodingKeys.auto.rawValue)
            case .function(let name):
                var container = encoder.container(keyedBy: CodingKeys.self)
                try container.encode(name, forKey: .function)
            }
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case model
        case messages
        case functions
        case functionCall = "function_call"
        case temperature
        case topP = "top_p"
        case n
        case stream
        case stop
        case maxTokens = "max_tokens"
        case presencePenalty = "presence_penalty"
        case frequencyPenalty = "frequency_penalty"
        case logitBias = "logit_bias"
        case user
        case responseFormat = "response_format"
    }
    
    public init(model: Model, messages: [ImageVisionChat], responseFormat: ResponseFormat? = nil, functions: [ChatFunctionDeclaration]? = nil, functionCall: FunctionCall? = nil, temperature: Double? = nil, topP: Double? = nil, n: Int? = nil, stop: [String]? = nil, maxTokens: Int? = nil, presencePenalty: Double? = nil, frequencyPenalty: Double? = nil, logitBias: [String : Int]? = nil, user: String? = nil, stream: Bool = false) {
        self.model = model
        self.messages = messages
        self.functions = functions
        self.functionCall = functionCall
        self.temperature = temperature
        self.topP = topP
        self.n = n
        self.responseFormat = responseFormat
        self.stop = stop
        self.maxTokens = maxTokens
        self.presencePenalty = presencePenalty
        self.frequencyPenalty = frequencyPenalty
        self.logitBias = logitBias
        self.user = user
        self.stream = stream
    }
}

public struct ImageVisionChat: Codable, Equatable {
    
    public static func == (lhs: ImageVisionChat, rhs: ImageVisionChat) -> Bool {
        lhs.id == rhs.id
    }
    
    private let id: UUID = UUID()
    public let role: Role
    public let content: Either<[ImageVisionContent]?, String?>
    
    public let name: String?
    public let functionCall: ChatFunctionCall?
    
    public enum Role: String, Codable, Equatable {
        case system
        case assistant
        case user
        case function
    }
    
    enum CodingKeys: String, CodingKey {
        case role
        case content
        case name
        case functionCall = "function_call"
    }
    
    public init(role: Role, content: Either<[ImageVisionContent]?, String?>,
                name: String? = nil,functionCall: ChatFunctionCall? = nil) {
        self.role = role
        self.content = content
        self.name = name
        self.functionCall = functionCall
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(role, forKey: .role)

        if let name = name {
            try container.encode(name, forKey: .name)
        }

        if let functionCall = functionCall {
            try container.encode(functionCall, forKey: .functionCall)
        }
        
        switch content {
        case .left(let value):
            try container.encode(value, forKey: .content)
        case .right(let value):
            try container.encode(value, forKey: .content)
        }
    }
}

public enum Either<T: Codable, U: Codable>: Codable {
    case left(T)
    case right(U)
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let value = try? container.decode(T.self) {
            self = .left(value)
        } else if let value = try? container.decode(U.self) {
            self = .right(value)
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid either value")
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch self {
        case .left(let value):
            try container.encode(value)
        case .right(let value):
            try container.encode(value)
        }
    }
}

public struct ImageVisionContent: Codable {
    public enum ChatType: String, Codable {
        case text
        case imageUrl = "image_url"
    }
    
    public struct ImageUrl: Codable {
        let url: String
        
        public init(url: String) {
            self.url = url
        }
    }
    
    let type: ChatType
    let text: String?
    let imageUrl: ImageUrl?
    
    public enum CodingKeys: String, CodingKey {
        case type
        case text
        case imageUrl = "image_url"
    }
    
    public init(type: ChatType, text: String? = nil, imageUrl: ImageUrl? = nil) {
        self.type = type
        self.text = text
        self.imageUrl = imageUrl
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        type = try container.decode(ChatType.self, forKey: .type)
        
        switch type {
        case .text:
            text = try container.decode(String.self, forKey: .text)
            imageUrl = nil
        case .imageUrl:
            text = nil
            imageUrl = try container.decode(ImageUrl.self, forKey: .imageUrl)
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        
        switch type {
        case .text:
            try container.encode(text, forKey: .text)
        case .imageUrl:
            try container.encode(imageUrl, forKey: .imageUrl)
        }
    }
}

