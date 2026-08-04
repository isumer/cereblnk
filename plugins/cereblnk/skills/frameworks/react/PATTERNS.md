---
name: react-patterns
genre: recipe
loaded_for: build, implement
versions: { react: ">=18", typescript: ">=5" }
---

# React Recipes

Complete implementations referenced by SKILL.md paths. Each recipe:
one line on when, then the whole thing. Constraints live in
`rules/frameworks/react/`; this file never restates them.

## §1 Memoized derivation
When a derived value is measured expensive (profiler evidence cited).

```tsx
const visibleRows = useMemo(
  () => rows.filter(matches(filter)).sort(byColumn(sort)),
  [rows, filter, sort],
);
```

## §2 Server state in a query layer
When fetched data must stay fresh after mutations.

```tsx
export function useOrders() {
  return useQuery({ queryKey: ['orders'], queryFn: api.listOrders });
}

export function useDeleteOrder() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: api.deleteOrder,
    onSuccess: () => qc.invalidateQueries({ queryKey: ['orders'] }),
  });
}
```

## §3 Effect trio — debounce, subscription, abortable fetch
When an effect genuinely synchronizes an external system.

```tsx
useEffect(() => {
  const t = setTimeout(() => search(query), 300);
  return () => clearTimeout(t);
}, [query]);

useEffect(() => {
  const sub = priceFeed.subscribe(symbol, setPrice);
  return () => sub.unsubscribe();
}, [symbol]);

useEffect(() => {
  const ac = new AbortController();
  fetchResults(q, { signal: ac.signal })
    .then(setResults)
    .catch(e => { if (e.name !== 'AbortError') setError(e); });
  return () => ac.abort();
}, [q]);
```

## §4 Four-state async surface
Every data view renders loading, error, empty, success.

```tsx
function Orders() {
  const { data, error, isLoading, refetch } = useOrders();
  if (isLoading) return <Skeleton rows={5} />;
  if (error)     return <ErrorState error={error} onRetry={refetch} />;
  if (!data.length) return <EmptyState action={<NewOrderButton />} />;
  return <OrderList orders={data} />;
}
```

## §5 Composition and compound components
When boolean mode flags multiply, or children need shared state.

```tsx
const TabsCtx = createContext<{active: string; set: (t: string) => void} | null>(null);

export function Tabs({ defaultTab, children }: TabsProps) {
  const [active, set] = useState(defaultTab);
  return <TabsCtx.Provider value={{ active, set }}>{children}</TabsCtx.Provider>;
}

export function Tab({ id, children }: TabProps) {
  const ctx = useContext(TabsCtx);
  if (!ctx) throw new Error('Tab must be used inside <Tabs>');
  return (
    <button role="tab" aria-selected={ctx.active === id} onClick={() => ctx.set(id)}>
      {children}
    </button>
  );
}

export function TabPanel({ id, children }: TabPanelProps) {
  const ctx = useContext(TabsCtx);
  return ctx?.active === id ? <div role="tabpanel">{children}</div> : null;
}
```

## §6 Hook extraction
When logic and markup share a component body.

```tsx
export function useCheckout() {
  const [step, setStep] = useState<Step>('cart');
  const { data: cart } = useQuery({ queryKey: ['cart'], queryFn: api.getCart });
  const submit = useMutation({ mutationFn: api.placeOrder,
    onSuccess: () => setStep('done') });
  return { step, setStep, cart, submit };
}

export function Checkout() {
  const { step, setStep, cart, submit } = useCheckout();
  if (!cart) return <Skeleton />;
  return <CheckoutSteps step={step} cart={cart}
                        onNext={setStep} onSubmit={() => submit.mutate(cart)} />;
}
```

## §7 Error boundary
One per route or feature shell; reset on navigation.

```tsx
export class FeatureBoundary extends Component<Props, { error?: Error }> {
  state = { error: undefined };
  static getDerivedStateFromError(error: Error) { return { error }; }
  componentDidCatch(error: Error, info: ErrorInfo) { report(error, info); }
  render() {
    if (this.state.error)
      return <ErrorState error={this.state.error}
                         onRetry={() => this.setState({ error: undefined })} />;
    return this.props.children;
  }
}
```
