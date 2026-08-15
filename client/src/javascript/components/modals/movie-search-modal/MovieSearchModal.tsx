import {FC, useEffect, useState} from 'react';
import {observer} from 'mobx-react-lite';

import TorrentActions from '@client/actions/TorrentActions';
import TorrentStore from '@client/stores/TorrentStore';
import UIStore from '@client/stores/UIStore';

import Modal from '../Modal';

interface Result {
  title: string;
  year: number | null;
  url: string;
}

const MovieSearchModal: FC = observer(() => {
  const active = UIStore.activeModal;
  const hash = active?.id === 'movie-search' ? active.hash : '';
  const name = TorrentStore.torrents[hash]?.name ?? '';
  const [results, setResults] = useState<Array<Result>>([]);
  const [query, setQuery] = useState('');
  const [loading, setLoading] = useState(true);
  const [failed, setFailed] = useState(false);

  useEffect(() => {
    let cancelled = false;
    setLoading(true);
    setFailed(false);
    TorrentActions.searchMovie(name)
      .then((data) => {
        if (!cancelled) {
          setQuery(data.query);
          setResults(data.results);
          setLoading(false);
        }
      })
      .catch(() => {
        if (!cancelled) {
          setFailed(true);
          setLoading(false);
        }
      });
    return () => {
      cancelled = true;
    };
  }, [name]);

  return (
    <Modal
      heading={<span>电影中文名</span>}
      size="medium"
      content={
        <div style={{padding: '1rem'}}>
          <div style={{marginBottom: '1rem', wordBreak: 'break-all'}}>
            <strong>文件名：</strong>
            {name}
          </div>
          {loading ? (
            <div>正在查询…</div>
          ) : failed ? (
            <div>查询失败，请稍后重试。</div>
          ) : results.length === 0 ? (
            <div>未找到匹配结果（搜索：{query}）。</div>
          ) : (
            <div>
              <div style={{marginBottom: '0.5rem'}}>搜索：{query}</div>
              {results.map((result) => (
                <div
                  key={`${result.title}-${result.year}-${result.url}`}
                  style={{padding: '0.5rem 0', borderBottom: '1px solid var(--color-border)'}}
                >
                  <a href={result.url} target="_blank" rel="noreferrer">
                    {result.title}
                    {result.year == null ? '' : ` (${result.year})`}
                  </a>
                </div>
              ))}
            </div>
          )}
        </div>
      }
    />
  );
});

export default MovieSearchModal;
