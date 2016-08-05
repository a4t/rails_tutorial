require 'test_helper'

#最後に、統合テストを書きます。
#今回の統合テストでは、ログイン、マイクロポストのページ分割の確認、
#無効なマイクロポストを投稿、有効なマイクロポストを投稿、マイクロポストの削除、
#そして他のユーザーのマイクロポストには [delete] リンクが表示されないことを確認、
#といった順でテストしていきます。
#いつものように、統合テストを生成するところから始めましょう。


class MicropostsInterfaceTest < ActionDispatch::IntegrationTest
  def setup
    @user = users(:michael)
  end

  test "micropost interface" do
    log_in_as(@user)
    get user_path(@user)
    assert_select 'li>span.content', count: 30
    get user_path(@user, page: 2)
    assert_select 'li>span.content', count: 4

    # 無効な送信
    assert_no_difference 'Micropost.count' do
      post microposts_path, micropost: { content: ' ' }
    end
    assert_no_difference 'Micropost.count' do
      post microposts_path, micropost: { content: 'a' * 141 }
    end

    # 有効な送信
    content = 'This micropost really ties the room together'
    assert_difference 'Micropost.count', 1 do
      post microposts_path, micropost: { content: content }
    end
    assert_redirected_to root_url
    follow_redirect!
    assert_match content, response.body

    # 投稿を削除する
    assert_select 'a', text: 'delete'
    first_micropost = @user.microposts.paginate(page: 1).first
    assert_difference 'Micropost.count', -1 do
      delete micropost_path(first_micropost)
    end

    # 違うユーザーのプロフィールにアクセスする
    get user_path(users(:archer))
    assert_select 'a', text: 'delete', count: 0
  end
end
