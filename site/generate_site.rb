require "erb"
require "net/http"
require "uri"
require "json"

Dir.chdir __dir__

def fetch_issues repo, token
    res = []
    page = 1
    loop do
        uri = "https://api.github.com/repos/#{repo}/issues?state=open&per_page=100&page=#{page}"
        uri = URI.parse(uri)
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
        req = Net::HTTP::Get.new(uri.request_uri)
        req["Authorization"] = "token #{token}" if token
        resp = http.request(req)
        issues = JSON.parse resp.body
        if issues[0] and issues[0][0] == "message"
            puts issues[1]
            exit 1
        end
        if issues.empty? or page > 10
            break
        end
        issues.each do |issue|
            res << {
                title: issue["title"],
                user: issue["user"]["login"],
                url: issue["html_url"],
            }
        end
        page += 1
    end
    res
end
def colored issues
    prev_color = 0
    random_color = -> do
        color = rand 5
        if color == prev_color
            color = (color + 1) % 5
        end
        prev_color = color
        "c#{color + 1}"
    end
    res = []
    issues.each do |issue|
        res << {
            type: "negai",
            url: ERB::Util.h(issue[:url]),
            text: ERB::Util.h(issue[:title]),
            color: random_color[],
        }
        if rand(3) == 0
            res << {
                type: "kazari",
                colors: (rand(3) + 4).times.map{random_color[]},
            }
        end
    end
    res
end

negais = if ARGV[0] == "test"
    [
        {
        type: "negai",
        url: "http://www.example.com/",
        text: "ナナチをモフれますように",
        color: "c4",
        },
        {
        type: "kazari",
        colors: ["c1", "c2", "c3", "c4", "c5"],
        },
        {
        type: "negai",
        url: "http://www.example.com/",
        text: "ナナチをモフれますようにナナナチをモフれますようにナナナチをモフれますようにナナナチをモフれますようにナナナチをモフれますように",
        color: "c2"
        },
    ]
else
    if ENV["GITHUB_REPOSITORY"] == nil
        puts "GITHUB_REPOSITORY is not set"
        exit 1
    end
    issues = fetch_issues ENV["GITHUB_REPOSITORY"], ENV["GITHUB_TOKEN"]
    colored issues
end



template = ERB.new(File.read("site.html.erb"))
def b negais
    negais = negais
    binding
end

res = template.result(b(negais))
File.write("dist/index.html", res)